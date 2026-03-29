'use client';

/**
 * Communication Module Main Page
 * Full chat interface with sidebar and chat window
 */

import { useState, useCallback } from 'react';
import { useToast } from '@/components/ui/Toast';
import { ChatSidebar } from '@/components/communication/ChatSidebar';
import { ChatWindow } from '@/components/communication/ChatWindow';
import useChat from '@/hooks/useChat';

/**
 * New Conversation Modal
 */
function NewConversationModal({ isOpen, onClose, onCreateDirect, isLoading }) {
  const [email, setEmail] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!email) return;
    try {
      await onCreateDirect(email);
      setEmail('');
      onClose();
    } catch (err) {
      console.error('Failed to create conversation:', err);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-card rounded-xl shadow-xl p-6 max-w-sm w-full">
        <h2 className="text-xl font-bold text-foreground mb-4">Start Conversation</h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-muted-foreground mb-1">
              User Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="user@example.com"
              className="w-full px-3 py-2 bg-muted text-foreground rounded-lg border border-border focus:outline-none focus:ring-2 focus:ring-primary"
              required
            />
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 bg-muted text-foreground rounded-lg hover:bg-muted/80 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="flex-1 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 disabled:opacity-50 transition"
            >
              {isLoading ? 'Creating...' : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function CommunicationPage() {
  const { addToast } = useToast();
  const [showNewConvModal, setShowNewConvModal] = useState(false);
  const chat = useChat();

  const handleCreateConversation = useCallback(
    async (email) => {
      try {
        // In real implementation, would fetch user ID by email first
        // For now, just create a direct conversation
        await chat.createConversation('direct', null, []);
        addToast({
          type: 'success',
          title: 'Conversation Created',
          message: 'New conversation started!',
        });
      } catch (err) {
        addToast({
          type: 'error',
          title: 'Error',
          message: err.message || 'Failed to create conversation',
        });
      }
    },
    [chat, addToast]
  );

  const handleSendMessage = useCallback(
    async (content, attachment) => {
      try {
        await chat.sendMessage(content, attachment);
      } catch (err) {
        addToast({
          type: 'error',
          title: 'Error',
          message: 'Failed to send message',
        });
      }
    },
    [chat, addToast]
  );

  return (
    <div className="flex h-screen bg-background">
      {/* Sidebar */}
      <div className="w-80 border-r border-border flex flex-col">
        <ChatSidebar
          conversations={chat.conversations}
          selectedConversationId={chat.selectedConvId}
          onSelectConversation={chat.setSelectedConvId}
          onCreateNew={() => setShowNewConvModal(true)}
          isLoadingConvs={chat.isLoadingConvs}
        />
      </div>

      {/* Chat Area */}
      <div className="flex-1 flex flex-col">
        {chat.selectedConvId ? (
          <ChatWindow
            conversationId={chat.selectedConvId}
            messages={chat.messages}
            currentUserId={typeof window !== 'undefined' ? localStorage.getItem('userId') : null}
            isLoading={chat.isLoadingMessages}
            onSendMessage={handleSendMessage}
            onLoadMore={() => {}}
          />
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-muted-foreground">
            <div className="text-center">
              <p className="text-lg font-medium mb-2">No Conversation Selected</p>
              <p className="text-sm">Select a conversation to start chatting</p>
              <button
                onClick={() => setShowNewConvModal(true)}
                className="mt-4 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition"
              >
                Start New Conversation
              </button>
            </div>
          </div>
        )}
      </div>

      {/* New Conversation Modal */}
      <NewConversationModal
        isOpen={showNewConvModal}
        onClose={() => setShowNewConvModal(false)}
        onCreateDirect={handleCreateConversation}
        isLoading={false}
      />
    </div>
  );
}
