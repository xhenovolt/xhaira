import { NextResponse } from 'next/server';
import { db } from '@/lib/db.js';
import { requirePermission } from '@/lib/permissions.js';
import {
  createConversation,
  getUserConversations,
  getConversationDetails,
  logCommunicationAudit,
  isParticipant,
} from '@/lib/communication-utils.js';

/**
 * GET /api/communication/conversations
 * Get all conversations for current user
 */
export async function GET(req) {
  try {
    const auth = await requirePermission(req, 'communication.view_conversations');
    if (auth.status === 403) return auth;
    
    const { userId } = auth;
    
    const conversations = await getUserConversations(userId);
    
    return NextResponse.json({
      success: true,
      conversations,
      count: conversations.length,
    });
  } catch (error) {
    console.error('Error fetching conversations:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

/**
 * POST /api/communication/conversations
 * Create a new conversation
 */
export async function POST(req) {
  try {
    const auth = await requirePermission(req, 'communication.create_conversation');
    if (auth.status === 403) return auth;
    
    const { userId } = auth;
    const body = await req.json();
    const { type, name, participants } = body;
    
    // Validation
    if (!type || !['direct', 'group', 'department'].includes(type)) {
      return NextResponse.json(
        { success: false, error: 'Invalid conversation type' },
        { status: 400 }
      );
    }
    
    if (type === 'direct') {
      if (!participants || participants.length !== 1) {
        return NextResponse.json(
          { success: false, error: 'Direct conversation requires exactly 1 other participant' },
          { status: 400 }
        );
      }
    }
    
    if (type === 'group' || type === 'department') {
      if (!name) {
        return NextResponse.json(
          { success: false, error: 'Group/department conversation requires a name' },
          { status: 400 }
        );
      }
    }
    
    // Create conversation
    const conversation = await createConversation({
      type,
      name: type !== 'direct' ? name : null,
      createdBy: userId,
      participants: participants || [userId],
    });
    
    // Fetch full details
    const details = await getConversationDetails(conversation.id, userId);
    
    return NextResponse.json({
      success: true,
      conversation: details,
    }, { status: 201 });
  } catch (error) {
    console.error('Error creating conversation:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

export async function POST(request) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return Response.json({ success: false, error: 'Unauthorized' }, { status: 403 });
    }

    const body = await request.json();
    const { type, name, description, avatar_url, member_ids = [] } = body;

    // ── Validate ──
    if (!type || !['direct', 'group'].includes(type)) {
      return Response.json(
        { success: false, error: 'Invalid conversation type' },
        { status: 400 }
      );
    }

    // For direct messages, must have exactly 2 members
    if (type === 'direct' && (!member_ids.length || member_ids.includes(user.id))) {
      return Response.json(
        { success: false, error: 'Direct message must have another user' },
        { status: 400 }
      );
    }

    // For groups, name is required
    if (type === 'group' && !name) {
      return Response.json(
        { success: false, error: 'Group name is required' },
        { status: 400 }
      );
    }

    // ── Check if direct conversation already exists ──
    if (type === 'direct') {
      const existing = await query(
        `
        SELECT c.id FROM conversations c
        WHERE c.type = 'direct'
        AND c.id IN (
          SELECT conversation_id FROM conversation_members 
          WHERE user_id = $1 OR user_id = $2
          GROUP BY conversation_id HAVING COUNT(*) = 2
        )
        LIMIT 1
        `,
        [user.id, member_ids[0]]
      );

      if (existing.rows.length > 0) {
        return Response.json({
          success: true,
          data: { id: existing.rows[0].id, existing: true },
        });
      }
    }

    // ── Create conversation ──
    const convResult = await query(
      `
      INSERT INTO conversations (type, name, description, avatar_url, created_by_user_id)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, type, name, created_at
      `,
      [type, name || null, description || null, avatar_url || null, user.id]
    );

    const conversationId = convResult.rows[0].id;

    // ── Add members ──
    const allMembers = [user.id, ...member_ids];
    for (const memberId of allMembers) {
      await query(
        `
        INSERT INTO conversation_members (conversation_id, user_id, role)
        VALUES ($1, $2, $3)
        `,
        [conversationId, memberId, memberId === user.id ? 'owner' : 'member']
      );
    }

    return Response.json(
      {
        success: true,
        data: convResult.rows[0],
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('[conversations POST] Error:', error.message);
    return Response.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
