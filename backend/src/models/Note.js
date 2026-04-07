const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  content: {
    type: String,
    default: '',
    maxlength: 10000
  },
  moodLevel: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  },
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }]
}, {
  timestamps: true
});

// Indexes
noteSchema.index({ userId: 1, createdAt: -1 });
noteSchema.index({ userId: 1, tags: 1 });
noteSchema.index({ title: 'text', content: 'text' });

noteSchema.methods.toJSON = function() {
  const obj = this.toObject();
  obj.id = obj._id;
  delete obj._id;
  delete obj.__v;
  return obj;
};

module.exports = mongoose.model('Note', noteSchema);
