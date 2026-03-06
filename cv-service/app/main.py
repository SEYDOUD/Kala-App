import base64
import uuid
from typing import Dict, List, Tuple

import cv2
import mediapipe as mp
import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field


app = FastAPI(title="Kala CV Service", version="1.3.0")
mp_pose = mp.solutions.pose

POSE_FLOW = ["front_relaxed", "left_profile", "right_profile"]
POSE_INSTRUCTIONS = {
    "front_relaxed": "Mettez-vous debout face camera, bras legerement ecartes, corps entier visible.",
    "left_profile": "Tournez-vous de profil gauche, restez droit et gardez les bras le long du corps.",
    "right_profile": "Tournez-vous de profil droit, restez droit et gardez les bras le long du corps.",
}


class SessionStartRequest(BaseModel):
    genre: str = Field(..., pattern="^(homme|femme)$")
    taille_cm: float = Field(..., ge=130, le=230)
    poids_kg: float = Field(..., ge=30, le=250)
    age: int = Field(..., ge=8, le=100)


class AnalyzeFrameRequest(BaseModel):
    image_base64: str
    confirm_capture: bool = False


def _create_pose_tracker():
    return mp_pose.Pose(
        static_image_mode=False,
        model_complexity=2,
        smooth_landmarks=True,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    )


def _distance(p1, p2) -> float:
    return ((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2) ** 0.5


def _decode_base64_image(image_base64: str) -> np.ndarray:
    data = image_base64
    if "," in image_base64:
        data = image_base64.split(",", 1)[1]
    raw = base64.b64decode(data)
    np_buf = np.frombuffer(raw, dtype=np.uint8)
    image = cv2.imdecode(np_buf, cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError("Image invalide")
    return image


def _prepare_image(image: np.ndarray) -> np.ndarray:
    h, w = image.shape[:2]
    if w > 1280:
        scale = 1280 / w
        image = cv2.resize(
            image,
            (int(w * scale), int(h * scale)),
            interpolation=cv2.INTER_AREA,
        )

    ycrcb = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
    y, cr, cb = cv2.split(ycrcb)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    y = clahe.apply(y)
    return cv2.cvtColor(cv2.merge((y, cr, cb)), cv2.COLOR_YCrCb2BGR)


def _landmarks_from_image(image: np.ndarray, pose_tracker):
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = pose_tracker.process(image_rgb)
    if not results.pose_landmarks:
        return None
    return results.pose_landmarks.landmark


def _visibility_score(landmarks) -> float:
    required = [
        mp_pose.PoseLandmark.NOSE,
        mp_pose.PoseLandmark.LEFT_SHOULDER,
        mp_pose.PoseLandmark.RIGHT_SHOULDER,
        mp_pose.PoseLandmark.LEFT_HIP,
        mp_pose.PoseLandmark.RIGHT_HIP,
        mp_pose.PoseLandmark.LEFT_ANKLE,
        mp_pose.PoseLandmark.RIGHT_ANKLE,
    ]
    vis = [landmarks[idx].visibility for idx in required]
    return float(sum(vis) / len(vis))


def _frame_quality_issue(landmarks, visibility_score: float):
    left_shoulder = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER]
    right_shoulder = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER]
    left_hip = landmarks[mp_pose.PoseLandmark.LEFT_HIP]
    right_hip = landmarks[mp_pose.PoseLandmark.RIGHT_HIP]
    nose = landmarks[mp_pose.PoseLandmark.NOSE]
    left_ankle = landmarks[mp_pose.PoseLandmark.LEFT_ANKLE]
    right_ankle = landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE]

    if visibility_score < 0.48:
        return "Eclairage insuffisant ou corps partiellement visible. Rapprochez-vous de la lumiere."

    torso_center_x = (left_shoulder.x + right_shoulder.x + left_hip.x + right_hip.x) / 4
    if torso_center_x < 0.12 or torso_center_x > 0.88:
        return "Recentrez-vous dans le cadre."

    ankles_y = (left_ankle.y + right_ankle.y) / 2
    body_height = ankles_y - nose.y
    if body_height < 0.42:
        return "Reculez un peu: le corps entier doit etre visible de la tete aux pieds."

    if min(left_ankle.visibility, right_ankle.visibility) < 0.38:
        return "Assurez-vous que les jambes et les pieds sont visibles."

    return None


def _evaluate_pose(landmarks, expected_pose: str, vis_score: float) -> Tuple[float, str]:
    left_shoulder = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER]
    right_shoulder = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER]
    left_hip = landmarks[mp_pose.PoseLandmark.LEFT_HIP]
    right_hip = landmarks[mp_pose.PoseLandmark.RIGHT_HIP]
    nose = landmarks[mp_pose.PoseLandmark.NOSE]

    shoulder_width = _distance(left_shoulder, right_shoulder)
    hip_width = _distance(left_hip, right_hip)
    torso_center = (
        left_shoulder.x + right_shoulder.x + left_hip.x + right_hip.x
    ) / 4

    if expected_pose == "front_relaxed":
        symmetry = max(0.0, 1 - abs(left_shoulder.y - right_shoulder.y) * 2.5)
        shoulder_factor = min(1.0, shoulder_width / 0.18)
        hip_factor = min(1.0, hip_width / 0.16)
        confidence = (
            0.32 * symmetry
            + 0.28 * shoulder_factor
            + 0.20 * hip_factor
            + 0.20 * vis_score
        )
        guide = "Face camera: redressez-vous et gardez les epaules alignees."
    else:
        shoulder_narrow = max(0.0, min(1.0, 1 - shoulder_width / 0.16))
        hip_narrow = max(0.0, min(1.0, 1 - hip_width / 0.14))
        nose_offset = min(1.0, abs(nose.x - torso_center) / 0.08)
        confidence = (
            0.42 * shoulder_narrow
            + 0.28 * hip_narrow
            + 0.15 * nose_offset
            + 0.15 * vis_score
        )
        if expected_pose == "left_profile":
            guide = "Tournez encore legerement vers la gauche."
        else:
            guide = "Tournez encore legerement vers la droite."

    return round(float(max(0.0, min(1.0, confidence))), 3), guide


def _extract_confirmed_features(landmarks):
    req = [
        mp_pose.PoseLandmark.NOSE,
        mp_pose.PoseLandmark.LEFT_SHOULDER,
        mp_pose.PoseLandmark.RIGHT_SHOULDER,
        mp_pose.PoseLandmark.LEFT_HIP,
        mp_pose.PoseLandmark.RIGHT_HIP,
        mp_pose.PoseLandmark.LEFT_ANKLE,
        mp_pose.PoseLandmark.RIGHT_ANKLE,
    ]
    if any(landmarks[idx].visibility < 0.45 for idx in req):
        return None

    nose = landmarks[mp_pose.PoseLandmark.NOSE]
    ls = landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER]
    rs = landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER]
    lh = landmarks[mp_pose.PoseLandmark.LEFT_HIP]
    rh = landmarks[mp_pose.PoseLandmark.RIGHT_HIP]
    la = landmarks[mp_pose.PoseLandmark.LEFT_ANKLE]
    ra = landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE]

    ankles_y = (la.y + ra.y) / 2
    body_height = ankles_y - nose.y
    if body_height <= 0.42:
        return None

    shoulder_ratio = _distance(ls, rs) / body_height
    hip_ratio = _distance(lh, rh) / body_height
    torso_ratio = ((_distance(ls, lh) + _distance(rs, rh)) / 2) / body_height
    leg_ratio = ((_distance(lh, la) + _distance(rh, ra)) / 2) / body_height

    return {
        "shoulder_ratio": shoulder_ratio,
        "hip_ratio": hip_ratio,
        "torso_ratio": torso_ratio,
        "leg_ratio": leg_ratio,
    }


def _clamp(value: float, min_value: float, max_value: float) -> float:
    return min(max(value, min_value), max_value)


def _round1(value: float) -> float:
    return round(value, 1)


def _median(values: List[float]):
    if not values:
        return None
    arr = sorted(values)
    mid = len(arr) // 2
    if len(arr) % 2 == 1:
        return arr[mid]
    return (arr[mid - 1] + arr[mid]) / 2


def _blend_with_limit(base: float, target: float, alpha: float, max_delta: float):
    mixed = (1 - alpha) * base + alpha * target
    delta = _clamp(mixed - base, -max_delta, max_delta)
    return _round1(base + delta)


def _apply_vision_adjustments(
    base_predictions: Dict[str, float],
    taille_cm: float,
    confirmed_features: List[Dict[str, float]],
) -> Dict[str, float]:
    if not confirmed_features:
        return base_predictions

    shoulder_ratio = _median([f["shoulder_ratio"] for f in confirmed_features if "shoulder_ratio" in f])
    torso_ratio = _median([f["torso_ratio"] for f in confirmed_features if "torso_ratio" in f])
    leg_ratio = _median([f["leg_ratio"] for f in confirmed_features if "leg_ratio" in f])

    result = dict(base_predictions)

    if shoulder_ratio is not None:
        observed_epaule = shoulder_ratio * taille_cm * 1.18
        result["epaule"] = _blend_with_limit(result["epaule"], observed_epaule, 0.33, 2.8)

    if torso_ratio is not None:
        observed_dos = torso_ratio * taille_cm * 0.95
        result["dos"] = _blend_with_limit(result["dos"], observed_dos, 0.28, 2.4)

    if leg_ratio is not None:
        observed_entre_jambe = leg_ratio * taille_cm * 0.88
        observed_entre_pied = leg_ratio * taille_cm * 0.85
        result["entre_jambe"] = _blend_with_limit(
            result["entre_jambe"], observed_entre_jambe, 0.30, 2.5
        )
        result["entre_pied"] = _blend_with_limit(
            result["entre_pied"], observed_entre_pied, 0.30, 2.5
        )

    return result


def _predict_measurements(
    genre: str,
    taille_cm: float,
    poids_kg: float,
    age: int,
    confirmed_features: List[Dict[str, float]],
) -> Dict[str, float]:
    taille_delta = taille_cm - 170
    poids_delta = poids_kg - 70
    age_delta = age - 30
    is_femme = genre == "femme"
    gender_frame_adjust = -1 if is_femme else 1

    predictions = {
        "tour_de_tete": _round1(
            _clamp(56 + taille_delta * 0.06 + poids_delta * 0.04 + age_delta * 0.02, 49, 64)
        ),
        "epaule": _round1(
            _clamp(44 + taille_delta * 0.20 + poids_delta * 0.06 + gender_frame_adjust * 2.8, 34, 58)
        ),
        "dos": _round1(
            _clamp(42 + taille_delta * 0.18 + poids_delta * 0.08 + gender_frame_adjust * 1.2, 34, 58)
        ),
        "ventre": _round1(
            _clamp(82 + poids_delta * 0.70 + age_delta * 0.20 + (-4 if is_femme else 2), 60, 150)
        ),
        "abdomen": _round1(
            _clamp(84 + poids_delta * 0.75 + age_delta * 0.18 + (-3 if is_femme else 2), 62, 155)
        ),
        "cuisse": _round1(
            _clamp(52 + poids_delta * 0.28 + taille_delta * 0.08 + (2.5 if is_femme else -1.5), 40, 85)
        ),
        "entre_jambe": _round1(
            _clamp(78 + taille_delta * 0.46 + (0.8 if is_femme else -0.8), 64, 100)
        ),
        "entre_pied": _round1(_clamp(75 + taille_delta * 0.42, 60, 98)),
    }
    if is_femme:
        predictions["poitrine"] = _round1(
            _clamp(88 + poids_delta * 0.45 + taille_delta * 0.12 + age_delta * 0.07, 72, 140)
        )

    return _apply_vision_adjustments(predictions, taille_cm, confirmed_features)


def _close_session_tracker(session: Dict):
    tracker = session.get("pose_tracker")
    if tracker is not None:
        try:
            tracker.close()
        except Exception:
            pass


sessions: Dict[str, Dict] = {}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/session/start")
def start_session(payload: SessionStartRequest):
    session_id = str(uuid.uuid4())
    sessions[session_id] = {
        "genre": payload.genre,
        "taille_cm": payload.taille_cm,
        "poids_kg": payload.poids_kg,
        "age": payload.age,
        "current_pose_idx": 0,
        "completed": False,
        "pose_tracker": _create_pose_tracker(),
        "smoothed_confidence": 0.0,
        "stable_ok_frames": 0,
        "stable_bad_frames": 0,
        "pose_ok_state": False,
        "confirmed_features": [],
    }

    pose = POSE_FLOW[0]
    return {
        "session_id": session_id,
        "current_pose": pose,
        "instruction": POSE_INSTRUCTIONS[pose],
        "remaining_poses": POSE_FLOW[1:],
    }


@app.post("/session/{session_id}/analyze")
def analyze_frame(session_id: str, payload: AnalyzeFrameRequest):
    session = sessions.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")
    if session["completed"]:
        return {"completed": True, "message": "Session deja terminee"}

    try:
        image = _prepare_image(_decode_base64_image(payload.image_base64))
        landmarks = _landmarks_from_image(image, session["pose_tracker"])
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))
    except Exception as err:
        raise HTTPException(status_code=500, detail=f"Erreur analyse frame: {err}")

    expected_pose = POSE_FLOW[session["current_pose_idx"]]
    if landmarks is None:
        session["smoothed_confidence"] = 0.0
        session["stable_ok_frames"] = 0
        session["stable_bad_frames"] = min(session.get("stable_bad_frames", 0) + 1, 12)
        session["pose_ok_state"] = False
        return {
            "completed": False,
            "current_pose": expected_pose,
            "pose_ok": False,
            "confidence": 0.0,
            "stability_score": 0.0,
            "frame_color": "red",
            "instruction": "Aucune pose detectee. Placez-vous en entier dans le cadre avec bonne lumiere.",
            "capture_confirmed": False,
            "advanced": False,
        }

    vis_score = _visibility_score(landmarks)
    issue = _frame_quality_issue(landmarks, vis_score)

    if issue is not None:
        raw_confidence = 0.0
        guide = issue
    else:
        raw_confidence, guide = _evaluate_pose(landmarks, expected_pose, vis_score)

    prev_smoothed = session.get("smoothed_confidence", 0.0)
    smoothed_confidence = 0.65 * prev_smoothed + 0.35 * raw_confidence
    session["smoothed_confidence"] = smoothed_confidence

    was_pose_ok = session.get("pose_ok_state", False)
    enter_threshold = 0.70
    keep_threshold = 0.63
    raw_min = 0.48 if was_pose_ok else 0.56

    pose_ok = (
        smoothed_confidence >= (keep_threshold if was_pose_ok else enter_threshold)
        and raw_confidence >= raw_min
    )
    session["pose_ok_state"] = pose_ok

    if pose_ok:
        session["stable_ok_frames"] = min(session.get("stable_ok_frames", 0) + 1, 12)
        session["stable_bad_frames"] = 0
    else:
        session["stable_bad_frames"] = min(session.get("stable_bad_frames", 0) + 1, 12)
        session["stable_ok_frames"] = max(session.get("stable_ok_frames", 0) - 1, 0)

    stability_score = min(1.0, session["stable_ok_frames"] / 5.0)

    if not payload.confirm_capture:
        return {
            "completed": False,
            "current_pose": expected_pose,
            "pose_ok": pose_ok,
            "confidence": round(smoothed_confidence, 3),
            "raw_confidence": round(raw_confidence, 3),
            "visibility_score": round(vis_score, 3),
            "stability_score": round(stability_score, 3),
            "frame_color": "green" if pose_ok else "red",
            "instruction": (
                "Pose correcte. Restez stable pour la capture." if pose_ok else guide
            ),
            "capture_confirmed": False,
            "advanced": False,
        }

    recently_stable = (
        session["stable_ok_frames"] >= 2
        and smoothed_confidence >= 0.62
        and vis_score >= 0.45
        and session["stable_bad_frames"] <= 1
    )

    if not pose_ok and not recently_stable:
        return {
            "completed": False,
            "current_pose": expected_pose,
            "pose_ok": False,
            "confidence": round(smoothed_confidence, 3),
            "stability_score": round(stability_score, 3),
            "frame_color": "red",
            "instruction": "Pose non stable. Gardez la position encore un instant.",
            "capture_confirmed": False,
            "advanced": False,
        }

    features = _extract_confirmed_features(landmarks)
    if features is not None:
        session["confirmed_features"].append(features)
        session["confirmed_features"] = session["confirmed_features"][-8:]

    session["current_pose_idx"] += 1
    session["smoothed_confidence"] = 0.0
    session["stable_ok_frames"] = 0
    session["stable_bad_frames"] = 0
    session["pose_ok_state"] = False

    if session["current_pose_idx"] >= len(POSE_FLOW):
        session["completed"] = True
        _close_session_tracker(session)
        return {
            "completed": True,
            "pose_ok": True,
            "confidence": round(smoothed_confidence, 3),
            "frame_color": "green",
            "message": "Capture terminee.",
            "capture_confirmed": True,
            "advanced": True,
            "mesures_predites": _predict_measurements(
                session["genre"],
                session["taille_cm"],
                session["poids_kg"],
                session["age"],
                session["confirmed_features"],
            ),
        }

    next_pose = POSE_FLOW[session["current_pose_idx"]]
    return {
        "completed": False,
        "pose_ok": True,
        "confidence": round(smoothed_confidence, 3),
        "stability_score": 1.0,
        "frame_color": "green",
        "capture_confirmed": True,
        "advanced": True,
        "current_pose": next_pose,
        "instruction": POSE_INSTRUCTIONS[next_pose],
    }


@app.get("/session/{session_id}")
def get_session(session_id: str):
    session = sessions.get(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session introuvable")

    current_pose = (
        POSE_FLOW[session["current_pose_idx"]]
        if session["current_pose_idx"] < len(POSE_FLOW)
        else None
    )

    return {
        "session_id": session_id,
        "completed": session["completed"],
        "current_pose": current_pose,
        "instruction": POSE_INSTRUCTIONS.get(current_pose) if current_pose else None,
    }