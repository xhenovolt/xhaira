import { NextResponse } from 'next/server';
import db from '@/lib/db.js';
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
