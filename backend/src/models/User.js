const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  firstName: {
    type: String,
    trim: true
  },
  lastName: {
    type: String,
    trim: true
  },
  phone: {
    type: String,
    trim: true
  },
  age: {
    type: Number,
    min: 13,
    max: 120
  },
  gender: {
    type: String,
    enum: ['male', 'female', 'other', 'prefer_not_to_say'],
    default: 'prefer_not_to_say'
  },
  avatarURL: {
    type: String,
    default: null
  },
  onboardingCompleted: {
    type: Boolean,
    default: false
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  verificationCodeHash: {
    type: String,
    default: null
  },
  verificationCodeExpiry: {
    type: Date,
    default: null
  }
}, {
  timestamps: true
});

userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.__v;
  delete obj.verificationCodeHash;
  delete obj.verificationCodeExpiry;
  obj.id = obj._id;
  delete obj._id;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
