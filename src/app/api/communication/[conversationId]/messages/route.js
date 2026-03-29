import { NextResponse } from 'next/server';
import { db } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';
import {
  createMessage,
  getConversationMessages,
  updateMessageStatus,
  deleteMessage,
  isParticipant,
  logCommunicationAudit,
  getMediaPermissions,
} from '@/lib/communication-utils.js';

/**
 * GET /api/communication/[conversationId]/messages
 * Get messages in a conversation with pagination
 */
export async function GET(req, { params }) {
  try {
    const auth = await requirePermission(req, 'communication.view_conversations');
    if (auth.status === 403) return auth;
    
    const { userId } = auth;
    const { conversationId } = params;
    const url = new URL(req.url);
    const limit = Math.min(parseInt(url.searchParams.get('limit')) || 30, 100);
    const offset = parseInt(url.searchParams.get('offset')) || 0;
    
    // Verify user is participant
    const isParticipantRes = await isParticipant(conversationId, userId);
    if (!isParticipantRes) {
      return NextResponse.json(
        { success: false, error: 'Not a member of this conversation' },
        { status: 403 }
      );
    }
    
    const messages = await getConversationMessages(conversationId, userId, limit, offset);
    
    return NextResponse.json({
      success: true,
      messages,
      count: messages.length,
      hasMore: messages.length === limit,
    });
  } catch (error) {
    console.error('Error fetching messages:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

/**
 * POST /api/communication/[conversationId]/messages
 * Send a new message
 */
export async function POST(req, { params }) {
  try {
    const auth = await requirePermission(req, 'communication.send_message');
    if (auth.status === 403) return auth;
    
    const { userId } = auth;
    const { conversationId } = params;
    
    // Verify user is participant
    const isParticipantRes = await isParticipant(conversationId, userId);
    if (!isParticipantRes) {
      return NextResponse.json(
        { success: false, error: 'Not a member of this conversation' },
        { status: 403 }
      );
    }
    
    const body = await req.json();
    const {
      content,
      messageType = 'text',
      mediaUrl = null,
      mediaType = null,
      mediaSize = null,
      replyToMessageId = null,
    } = body;
    
    // Validation
    if (!content && messageType === 'text') {
      return NextResponse.json(
        { success: false, error: 'Message content is required' },
        { status: 400 }
      );
    }
    
    if (!['text', 'image', 'video', 'audio', 'file'].includes(messageType)) {
      return NextResponse.json(
        { success: false, error: 'Invalid message type' },
        { status: 400 }
      );
    }
    
    // If media, validate against permissions
    if (messageType !== 'text') {
      const permissions = await getMediaPermissions();
      const typePerms = permissions.find(p => p.file_type === mediaType);
      
      if (!typePerms || !typePerms.allowed) {
        return NextResponse.json(
          { success: false, error: `${mediaType} uploads are not allowed` },
          { status: 403 }
        );
      }
      
      if (mediaSize && typePerms.max_size_mb && mediaSize / (1024 * 1024) > typePerms.max_size_mb) {
        return NextResponse.json(
          { success: false, error: `File exceeds maximum size of ${typePerms.max_size_mb}MB` },
          { status: 400 }
        );
      }
    }
    
    // Create message
    const message = await createMessage({
      conversationId: parseInt(conversationId),
      senderId: userId,
      content,
      messageType,
      mediaUrl,
      mediaType,
      mediaSize,
      replyToMessageId,
    });
    
    return NextResponse.json({
      success: true,
      message,
    }, { status: 201 });
  } catch (error) {
    console.error('Error sending message:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
        { status: 403 }
      );
    }

    // ── Get messages ──
    const result = await query(
      `
      SELECT 
        m.id, m.conversation_id, m.sender_id, m.content, m.message_type,
        m.media_url, m.media_type, m.file_name, m.file_size,
        m.delivery_status, m.is_edited, m.edited_at, m.created_at,
        u.name as sender_name, u.email as sender_email
      FROM messages m
      LEFT JOIN users u ON m.sender_id = u.id
      WHERE m.conversation_id = $1 AND m.is_deleted = false
      ORDER BY m.created_at DESC
      LIMIT $2 OFFSET $3
      `,
      [conversationId, limit, offset]
    );

    // ── Mark messages as delivered ──
    await query(
      `
      UPDATE messages
      SET delivery_status = 'delivered'
      WHERE conversation_id = $1 AND sender_id != $2 AND delivery_status = 'sent'
      `,
      [conversationId, user.id]
    ).catch(() => {});

    return Response.json({
      success: true,
      data: result.rows.reverse(), // Reverse to show oldest first
      count: result.rows.length,
    });
  } catch (error) {
    console.error('[messages GET] Error:', error.message);
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

export async function POST(request, { params }) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return Response.json({ success: false, error: 'Unauthorized' }, { status: 403 });
    }

    const { conversationId } = params;
    const body = await request.json();
    const { content, message_type = 'text', media_url, media_type, file_name, file_size } = body;

    // ── Validate ──
    if (!content) {
      return Response.json(
        { success: false, error: 'Message content is required' },
        { status: 400 }
      );
    }

    // ── Verify user is member ──
    const membership = await query(
      `SELECT id FROM conversation_members WHERE conversation_id = $1 AND user_id = $2 AND is_active = true`,
      [conversationId, user.id]
    );

    if (membership.rows.length === 0) {
      return Response.json(
        { success: false, error: 'Not a member of this conversation' },
        { status: 403 }
      );
    }

    // ── Insert message ──
    const result = await query(
      `
      INSERT INTO messages (
        conversation_id, sender_id, content, message_type,
        media_url, media_type, file_name, file_size,
        delivery_status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'sent')
      RETURNING id, created_at, delivery_status
      `,
      [conversationId, user.id, content, message_type, media_url || null, media_type || null, file_name || null, file_size || null]
    );

    const messageId = result.rows[0].id;

    // ── Update conversation's last_message_at ──
    await query(
      `UPDATE conversations SET last_message_at = NOW() WHERE id = $1`,
      [conversationId]
    ).catch(() => {});

    // ── Notify other members ──
    await query(
      `
      INSERT INTO notifications (user_id, title, message, type, reference_type, reference_id)
      SELECT cm.user_id, $1, $2, 'message', 'message', $3
      FROM conversation_members cm
      WHERE cm.conversation_id = $4 AND cm.user_id != $5 AND cm.is_active = true
      `,
      [`New message in conversation`, `${user.name}: ${content.substring(0, 50)}...`, messageId, conversationId, user.id]
    ).catch(() => {});

    return Response.json(
      {
        success: true,
        data: {
          id: messageId,
          conversation_id: conversationId,
          sender_id: user.id,
          content,
          message_type,
          created_at: result.rows[0].created_at,
          delivery_status: 'sent',
        },
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('[messages POST] Error:', error.message);
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
