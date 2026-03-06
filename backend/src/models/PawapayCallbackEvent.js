const mongoose = require('mongoose');

const pawapayCallbackEventSchema = new mongoose.Schema(
  {
    callback_type: {
      type: String,
      enum: ['deposits', 'payouts', 'refunds'],
      required: true,
    },
    external_id: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      required: true,
      trim: true,
      default: 'unknown',
    },
    dedupe_key: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    reference_candidates: {
      type: [String],
      default: [],
    },
    payload: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },
    headers: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    duplicate_count: {
      type: Number,
      default: 0,
    },
    last_received_at: {
      type: Date,
      default: Date.now,
    },
    commande_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Commande',
      default: null,
    },
    processing: {
      matched_commande: {
        type: Boolean,
        default: false,
      },
      updated_commande: {
        type: Boolean,
        default: false,
      },
      payment_status_applied: {
        type: String,
        default: null,
      },
      message: {
        type: String,
        default: null,
      },
    },
    processed_at: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    collection: 'pawapay_callback_event',
  }
);

pawapayCallbackEventSchema.index({ callback_type: 1, external_id: 1, status: 1 });
pawapayCallbackEventSchema.index({ processed_at: -1 });

module.exports = mongoose.model('PawapayCallbackEvent', pawapayCallbackEventSchema);
