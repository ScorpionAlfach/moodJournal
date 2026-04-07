const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  role: {
    type: String,
    enum: ['user', 'assistant'],
    required: true
  },
  content: {
    type: String,
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

const conversationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  messages: [messageSchema]
}, {
  timestamps: true
});

conversationSchema.index({ userId: 1, updatedAt: -1 });

conversationSchema.methods.toJSON = function() {
  const obj = this.toObject();
  obj.id = obj._id;
  delete obj._id;
  delete obj.__v;

  obj.messages = obj.messages.map(msg => ({
    id: msg._id.toString(),
    role: msg.role,
    content: msg.content,
    timestamp: msg.timestamp
  }));

  return obj;
};

module.exports = mongoose.model('Conversation', conversationSchema);
