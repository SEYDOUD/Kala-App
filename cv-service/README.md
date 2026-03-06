# CV Service (Guided Pose + Measurement Prediction)

Service de computer vision pour guider l'utilisateur:

1. Debout face camera
2. Profil gauche
3. Profil droit

Endpoints:
- `GET /health`
- `POST /session/start`
- `POST /session/{session_id}/analyze`
- `GET /session/{session_id}`

`/analyze` attend une image base64 (`image_base64`) et renvoie:
- le niveau de confiance de la pose
- les instructions de correction
- passage automatique a la pose suivante
- les mesures predites quand la capture est terminee
