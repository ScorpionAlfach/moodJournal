const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

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
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  phone: {
    type: String,
    required: true,
    trim: true
  },
  age: {
    type: Number,
    required: true,
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
  verificationCode: {
    type: String,
    default: null
  },
  verificationCodeExpires: {
    type: Date,
    default: null
  },
  isVerified: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

userSchema.methods.generateVerificationCode = function() {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  this.verificationCode = code;
  this.verificationCodeExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
  return code;
};

userSchema.methods.verifyCode = function(code) {
  if (!this.verificationCode || !this.verificationCodeExpires) {
    return false;
  }
  if (new Date() > this.verificationCodeExpires) {
    return false;
  }
  return this.verificationCode === code;
};

userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.verificationCode;
  delete obj.verificationCodeExpires;
  delete obj.__v;
  obj.id = obj._id;
  delete obj._id;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
