import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { db } from '../config/database';
import { getFabricClient } from '../fabric/fabricClient';
import { logger } from '../utils/logger';
import { authenticate, authorize } from '../middleware/auth';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'herbaltrace-secret-key-change-in-production';
const JWT_EXPIRY: string = (process.env.JWT_EXPIRES_IN || '24h') as string;
const JWT_REFRESH_EXPIRY: string = (process.env.JWT_REFRESH_EXPIRES_IN || '7d') as string;

/**
 * @route   POST /api/v1/auth/registration-request
 * @desc    Submit registration request (for farmers and other stakeholders)
 * @access  Public
 */
router.post('/registration-request', async (req: Request, res: Response) => {
  try {
    const {
      fullName,
      phone,
      email,
      locationDistrict,
      locationState,
      locationCoordinates,
      speciesInterest,
      farmSizeAcres,
      experienceYears,
      farmPhotos,
      certifications,
      role,
      organizationName,
      aadharNumber
    } = req.body;

    // Validation
    if (!fullName || !phone || !email || !role) {
      return res.status(400).json({
        success: false,
        message: 'Please provide fullName, phone, email, and role'
      });
    }

    // Check if email already has a pending request
    const existing = db.prepare(
      'SELECT id FROM registration_requests WHERE email = ? AND status = ?'
    ).get(email, 'pending');

    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'You already have a pending registration request'
      });
    }

    // Insert registration request
    const id = uuidv4();
    db.prepare(`
      INSERT INTO registration_requests (
        id, full_name, phone, email, role, organization_name, location_district, location_state,
        location_coordinates, species_interest, farm_size_acres, experience_years,
        farm_photos, certifications, aadhar_number
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id,
      fullName,
      phone,
      email,
      role || 'Farmer',
      organizationName || null,
      locationDistrict || null,
      locationState || null,
      locationCoordinates ? JSON.stringify(locationCoordinates) : null,
      speciesInterest ? JSON.stringify(speciesInterest) : null,
      farmSizeAcres || null,
      experienceYears || null,
      farmPhotos ? JSON.stringify(farmPhotos) : null,
      certifications ? JSON.stringify(certifications) : null,
      aadharNumber || null
    );

    logger.info(`Registration request submitted: ${id} (${email})`);

    res.status(201).json({
      success: true,
      message: 'Registration request submitted successfully. Admin will review and approve.',
      data: {
        requestId: id,
        email,
        status: 'pending'
      }
    });
  } catch (error: any) {
    logger.error('Registration request error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to submit registration request'
    });
  }
});

/**
 * @route   GET /api/v1/auth/registration-requests
 * @desc    Get all registration requests (admin only)
 * @access  Private (Admin)
 */
router.get('/registration-requests', authenticate, authorize('Admin'), async (req: Request, res: Response) => {
  try {
    const { status } = req.query;

    let query = 'SELECT * FROM registration_requests';
    const params: any[] = [];

    if (status) {
      query += ' WHERE status = ?';
      params.push(status);
    }

    query += ' ORDER BY request_date DESC';

    const requests = db.prepare(query).all(...params);

    // Parse JSON fields
    const parsedRequests = requests.map((r: any) => ({
      ...r,
      locationCoordinates: r.location_coordinates ? JSON.parse(r.location_coordinates) : null,
      speciesInterest: r.species_interest ? JSON.parse(r.species_interest) : null,
      farmPhotos: r.farm_photos ? JSON.parse(r.farm_photos) : null,
      certifications: r.certifications ? JSON.parse(r.certifications) : null
    }));

    res.status(200).json({
      success: true,
      count: parsedRequests.length,
      data: parsedRequests
    });
  } catch (error: any) {
    logger.error('Get registration requests error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get registration requests'
    });
  }
});

/**
 * @route   POST /api/v1/auth/registration-requests/:id/approve
 * @desc    Approve registration request and create user
 * @access  Private (Admin)
 */
router.post('/registration-requests/:id/approve', authenticate, authorize('Admin'), async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { role, orgName, orgMsp } = req.body;
    const adminUserId = (req as any).user.userId;

    if (!role || !orgName) {
      return res.status(400).json({
        success: false,
        message: 'Please provide role and orgName'
      });
    }

    // Get registration request
    const request: any = db.prepare('SELECT * FROM registration_requests WHERE id = ?').get(id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Request already ${request.status}`
      });
    }

    // Auto-generate credentials
    const userId = `${role.toLowerCase()}-${Date.now()}-${Math.random().toString(36).substr(2, 4)}`;
    const username = request.email.split('@')[0];
    const password = `HT${Math.random().toString(36).substr(2, 8).toUpperCase()}`;

    // Hash password
    const passwordHash = bcrypt.hashSync(password, 10);

    // Enroll user in Fabric network using admin certificates
    // This doesn't require CA servers to be running
    try {
      const { enrollUserWithAdminCert } = await import('../utils/enrollUser');
      const enrolled = await enrollUserWithAdminCert(
        userId,
        orgName,
        `${orgName.toLowerCase()}.department1`
      );
      if (enrolled) {
        logger.info(`✅ User ${userId} enrolled in Fabric network`);
      } else {
        logger.warn(`⚠️  Failed to enroll ${userId} in Fabric (continuing)`);
      }
    } catch (fabricError) {
      logger.warn('Fabric enrollment warning (continuing):', fabricError);
      // Continue even if Fabric enrollment fails - user can still use the app
    }

    // Create user in database
    db.prepare(`
      INSERT INTO users (
        id, user_id, username, email, password_hash, full_name, phone, role,
        org_name, org_msp, affiliation, location_district, location_state, location_coordinates, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      uuidv4(),
      userId,
      username,
      request.email,
      passwordHash,
      request.full_name,
      request.phone,
      role,
      orgName,
      orgMsp || `${orgName}MSP`,
      `${orgName.toLowerCase()}.department1`,
      request.location_district,
      request.location_state,
      request.location_coordinates,
      adminUserId
    );

    // Update registration request
    db.prepare(`
      UPDATE registration_requests
      SET status = ?, approved_by = ?, approved_date = datetime('now')
      WHERE id = ?
    `).run('approved', adminUserId, id);

    logger.info(`Registration approved: ${id} -> User created: ${userId}`);

    res.status(200).json({
      success: true,
      message: 'Registration request approved and user created',
      data: {
        userId,
        username,
        password, // Send password once - user should change it
        email: request.email,
        fullName: request.full_name,
        role,
        orgName,
        message: 'Please save these credentials securely and change password after first login'
      }
    });
  } catch (error: any) {
    logger.error('Approve registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve registration'
    });
  }
});

/**
 * @route   POST /api/v1/auth/registration-requests/:id/reject
 * @desc    Reject registration request
 * @access  Private (Admin)
 */
router.post('/registration-requests/:id/reject', authenticate, authorize('Admin'), async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const adminUserId = (req as any).user.userId;

    if (!reason) {
      return res.status(400).json({
        success: false,
        message: 'Please provide rejection reason'
      });
    }

    // Get registration request
    const request: any = db.prepare('SELECT * FROM registration_requests WHERE id = ?').get(id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Request already ${request.status}`
      });
    }

    // Update registration request
    db.prepare(`
      UPDATE registration_requests
      SET status = ?, approved_by = ?, approved_date = datetime('now'), rejection_reason = ?
      WHERE id = ?
    `).run('rejected', adminUserId, reason, id);

    logger.info(`Registration rejected: ${id} by ${adminUserId}`);

    res.status(200).json({
      success: true,
      message: 'Registration request rejected',
      data: {
        requestId: id,
        status: 'rejected',
        reason
      }
    });
  } catch (error: any) {
    logger.error('Reject registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject registration'
    });
  }
});

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide username and password'
      });
    }

    // Get user (by username or email)
    const user: any = db.prepare(
      'SELECT * FROM users WHERE (username = ? OR email = ?) AND status = ?'
    ).get(username, username, 'active');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Verify password
    const isMatch = bcrypt.compareSync(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Update last login
    db.prepare("UPDATE users SET last_login = datetime('now') WHERE id = ?").run(user.id);

    // Create JWT
    const tokenPayload = {
      userId: user.user_id,
      username: user.username,
      email: user.email,
      fullName: user.full_name,
      orgName: user.org_name,
      role: user.role
    };
    const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: JWT_EXPIRY as any });

    // Create refresh token
    const refreshPayload = { userId: user.user_id };
    const refreshToken = jwt.sign(refreshPayload, JWT_SECRET, { expiresIn: JWT_REFRESH_EXPIRY as any });

    logger.info(`User logged in: ${user.user_id} (${user.username})`);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        refreshToken,
        user: {
          userId: user.user_id,
          username: user.username,
          email: user.email,
          fullName: user.full_name,
          orgName: user.org_name,
          role: user.role
        }
      }
    });
  } catch (error: any) {
    logger.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
});

/**
 * @route   POST /api/v1/auth/refresh
 * @desc    Refresh access token
 * @access  Public
 */
router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token required'
      });
    }

    // Verify refresh token
    const decoded: any = jwt.verify(refreshToken, JWT_SECRET);

    // Get user
    const user: any = db.prepare('SELECT * FROM users WHERE user_id = ? AND status = ?').get(decoded.userId, 'active');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }

    // Create new access token
    const tokenPayload = {
      userId: user.user_id,
      username: user.username,
      email: user.email,
      fullName: user.full_name,
      orgName: user.org_name,
      role: user.role
    };
    const token = jwt.sign(tokenPayload, JWT_SECRET, { expiresIn: JWT_EXPIRY as any });

    res.status(200).json({
      success: true,
      message: 'Token refreshed successfully',
      data: { token }
    });
  } catch (error: any) {
    logger.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid or expired refresh token'
    });
  }
});

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', authenticate, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;

    const user: any = db.prepare('SELECT * FROM users WHERE user_id = ?').get(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      data: {
        userId: user.user_id,
        username: user.username,
        email: user.email,
        fullName: user.full_name,
        phone: user.phone,
        role: user.role,
        orgName: user.org_name,
        orgMsp: user.org_msp,
        status: user.status,
        createdAt: user.created_at,
        lastLogin: user.last_login
      }
    });
  } catch (error: any) {
    logger.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get profile'
    });
  }
});

/**
 * @route   POST /api/v1/auth/change-password
 * @desc    Change password
 * @access  Private
 */
router.post('/change-password', authenticate, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user.userId;
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide old and new password'
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 8 characters'
      });
    }

    // Get user
    const user: any = db.prepare('SELECT * FROM users WHERE user_id = ?').get(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Verify old password
    const isMatch = bcrypt.compareSync(oldPassword, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Old password is incorrect'
      });
    }

    // Hash new password
    const newPasswordHash = bcrypt.hashSync(newPassword, 10);

    // Update password
    db.prepare("UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE user_id = ?").run(
      newPasswordHash,
      userId
    );

    logger.info(`Password changed for user: ${userId}`);

    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error: any) {
    logger.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to change password'
    });
  }
});

/**
 * @route   DELETE /api/v1/auth/registration-requests/:id
 * @desc    Delete registration request (permanently remove from database)
 * @access  Private (Admin)
 */
router.delete('/registration-requests/:id', authenticate, authorize('Admin'), async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const adminUserId = (req as any).user.userId;

    // Get registration request
    const request: any = db.prepare('SELECT * FROM registration_requests WHERE id = ?').get(id);

    if (!request) {
      return res.status(404).json({
        success: false,
        message: 'Registration request not found'
      });
    }

    // Delete the registration request
    db.prepare('DELETE FROM registration_requests WHERE id = ?').run(id);

    logger.info(`Registration deleted: ${id} by ${adminUserId}`);

    res.status(200).json({
      success: true,
      message: 'Registration request deleted successfully',
      data: {
        requestId: id
      }
    });
  } catch (error: any) {
    logger.error('Delete registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete registration request'
    });
  }
});

export default router;
