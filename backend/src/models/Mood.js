const mongoose = require('mongoose');

const moodSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  level: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  note: {
    type: String,
    default: null,
    maxlength: 1000
  },
  factors: [{
    type: String,
    enum: ['sleep', 'no_sleep', 'exercise', 'work', 'family', 'friends', 'health', 'weather', 'food', 'hobby']
  }],
  date: {
    type: Date,
    required: true
  }
}, {
  timestamps: true
});

// Index for efficient queries
moodSchema.index({ userId: 1, date: -1 });
moodSchema.index({ userId: 1, createdAt: -1 });

moodSchema.methods.toJSON = function() {
  const obj = this.toObject();
  obj.id = obj._id;
  delete obj._id;
  delete obj.__v;
  return obj;
};

module.exports = mongoose.model('Mood', moodSchema);
