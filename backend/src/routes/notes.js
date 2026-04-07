const express = require('express');
const { body, query, param, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const Note = require('../models/Note');

const router = express.Router();

// GET /api/notes - Get notes with filtering
router.get('/',
  auth,
  [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('search').optional().trim(),
    query('moodLevels').optional(),
    query('tags').optional(),
    query('sortBy').optional().isIn(['date_desc', 'date_asc', 'title_asc', 'title_desc'])
  ],
  async (req, res) => {
    try {
      const userId = req.user._id;
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const skip = (page - 1) * limit;

      // Build filter
      const filter = { userId };

      // Search filter
      if (req.query.search) {
        filter.$or = [
          { title: { $regex: req.query.search, $options: 'i' } },
          { content: { $regex: req.query.search, $options: 'i' } }
        ];
      }

      // Mood levels filter
      if (req.query.moodLevels) {
        const levels = req.query.moodLevels.split(',').map(l => parseInt(l));
        filter.moodLevel = { $in: levels };
      }

      // Tags filter
      if (req.query.tags) {
        const tags = req.query.tags.split(',').map(t => t.trim().toLowerCase());
        filter.tags = { $in: tags };
      }

      // Sort options
      let sort = { createdAt: -1 };
      switch (req.query.sortBy) {
        case 'date_asc':
          sort = { createdAt: 1 };
          break;
        case 'title_asc':
          sort = { title: 1 };
          break;
        case 'title_desc':
          sort = { title: -1 };
          break;
      }

      const [notes, total] = await Promise.all([
        Note.find(filter).sort(sort).skip(skip).limit(limit),
        Note.countDocuments(filter)
      ]);

      res.json({
        notes: notes.map(n => n.toJSON()),
        total,
        page,
        limit
      });
    } catch (error) {
      console.error('Get notes error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// GET /api/notes/:id - Get single note
router.get('/:id',
  auth,
  [
    param('id').isMongoId().withMessage('Неверный ID заметки')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const note = await Note.findOne({
        _id: req.params.id,
        userId: req.user._id
      });

      if (!note) {
        return res.status(404).json({ message: 'Заметка не найдена' });
      }

      res.json(note.toJSON());
    } catch (error) {
      console.error('Get note error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/notes - Create note
router.post('/',
  auth,
  [
    body('title').trim().notEmpty().withMessage('Введите заголовок').isLength({ max: 200 }),
    body('content').optional().trim().isLength({ max: 10000 }),
    body('moodLevel').optional({ nullable: true }).isInt({ min: 1, max: 5 }),
    body('tags').optional().isArray()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { title, content, moodLevel, tags = [] } = req.body;

      const note = new Note({
        userId: req.user._id,
        title,
        content: content || '',
        moodLevel: moodLevel || null,
        tags: tags.map(t => t.trim().toLowerCase())
      });

      await note.save();

      res.status(201).json(note.toJSON());
    } catch (error) {
      console.error('Create note error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// PUT /api/notes/:id - Update note
router.put('/:id',
  auth,
  [
    param('id').isMongoId(),
    body('title').optional().trim().notEmpty().isLength({ max: 200 }),
    body('content').optional().trim().isLength({ max: 10000 }),
    body('moodLevel').optional({ nullable: true }).isInt({ min: 1, max: 5 }),
    body('tags').optional().isArray()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const note = await Note.findOne({
        _id: req.params.id,
        userId: req.user._id
      });

      if (!note) {
        return res.status(404).json({ message: 'Заметка не найдена' });
      }

      const { title, content, moodLevel, tags } = req.body;

      if (title !== undefined) note.title = title;
      if (content !== undefined) note.content = content;
      if (moodLevel !== undefined) note.moodLevel = moodLevel;
      if (tags !== undefined) note.tags = tags.map(t => t.trim().toLowerCase());

      await note.save();

      res.json(note.toJSON());
    } catch (error) {
      console.error('Update note error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// DELETE /api/notes/:id - Delete note
router.delete('/:id',
  auth,
  [
    param('id').isMongoId()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const note = await Note.findOneAndDelete({
        _id: req.params.id,
        userId: req.user._id
      });

      if (!note) {
        return res.status(404).json({ message: 'Заметка не найдена' });
      }

      res.json({ message: 'Заметка удалена' });
    } catch (error) {
      console.error('Delete note error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

module.exports = router;
