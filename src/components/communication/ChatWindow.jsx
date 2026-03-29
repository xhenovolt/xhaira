'use client';

/**
 * Chat Window Component
 * Displays messages for a conversation with message bubbles, typing indicators, etc.
 */

import { useEffect, useRef, useState, useCallback } from 'react';
import { Send, Plus, Paperclip, Image as ImageIcon, X, Check, CheckCheck } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const DELIVERY_ICONS = {
  sent: <Check className="w-3 h-3" />,
  delivered: <Check className="w-3 h-3" />,
  seen: <CheckCheck className="w-3 h-3" />,
};

export function ChatWindow({
  conversationId,
  messages = [],
  currentUserId,
  isLoading = false,
  onSendMessage,
  onLoadMore,
  hasMore = false,
}) {
  const messagesEndRef = useRef(null);
  const [text, setText] = useState('');
  const [isSending, setSending] = useState(false);
  const [attachment, setAttachment] = useState(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSend = async () => {
    if (!text.trim() && !attachment) return;

    setSending(true);
    try {
      await onSendMessage(text, attachment);
      setText('');
      setAttachment(null);
    } finally {
      setSending(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey && !isSending) {
      e.preventDefault();
      handleSend();
    }
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-full bg-background text-foreground">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        <p className="mt-2">Loading messages...</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {hasMore && (
          <button
            onClick={onLoadMore}
            className="mx-auto px-4 py-1 text-xs text-muted-foreground hover:text-foreground transition"
          >
            Load earlier messages
          </button>
        )}

        <AnimatePresence initial={false}>
          {messages?.map((msg, idx) => {
            const isOwn = msg.sender_id === currentUserId;
            return (
              <motion.div
                key={msg.id || idx}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.95 }}
                className={`flex ${isOwn ? 'justify-end' : 'justify-start'} gap-2`}
              >
                <div
                  className={`max-w-xs px-4 py-2 rounded-lg ${
                    isOwn
                      ? 'bg-primary text-primary-foreground rounded-br-none'
                      : 'bg-muted text-foreground rounded-bl-none'
                  }`}
                >
                  {/* Message Content */}
                  {msg.message_type === 'text' && (
                    <p className="break-words text-sm">{msg.content}</p>
                  )}

                  {msg.message_type === 'image' && msg.media_url && (
                    <img
                      src={msg.media_url}
                      alt="Image"
                      className="max-w-xs rounded max-h-64 object-cover"
                    />
                  )}

                  {msg.message_type === 'file' && (
                    <div className="flex items-center gap-2">
                      <Paperclip className="w-4 h-4" />
                      <a
                        href={msg.media_url}
                        download={msg.file_name}
                        className="text-sm underline hover:opacity-80"
                      >
                        {msg.file_name || 'Download'}
                      </a>
                    </div>
                  )}

                  {/* Time + Delivery Status */}
                  <div className="flex items-center justify-end gap-1 mt-1 text-xs opacity-70">
                    {new Date(msg.created_at).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                    {isOwn && DELIVERY_ICONS[msg.delivery_status]}
                  </div>
                </div>
              </motion.div>
            );
          })}
        </AnimatePresence>

        <div ref={messagesEndRef} />
      </div>

      {/* Attachment Preview */}
      {attachment && (
        <div className="px-4 py-2 bg-muted border-t border-border">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Paperclip className="w-4 h-4 text-muted-foreground" />
              <span className="text-sm text-muted-foreground">{attachment.name}</span>
            </div>
            <button
              onClick={() => setAttachment(null)}
              className="p-1 hover:bg-background rounded transition"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Message Input */}
      <div className="border-t border-border bg-background p-4 space-y-2">
        <div className="flex gap-2 items-end">
          {/* Attachment Button */}
          <button
            className="p-2 hover:bg-muted rounded-lg transition text-muted-foreground hover:text-foreground"
            title="Attach file"
          >
            <Paperclip className="w-5 h-5" />
          </button>

          {/* Image Button */}
          <button
            className="p-2 hover:bg-muted rounded-lg transition text-muted-foreground hover:text-foreground"
            title="Attach image"
          >
            <ImageIcon className="w-5 h-5" />
          </button>

          {/* Text Input */}
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Type a message..."
            className="flex-1 px-4 py-2 bg-muted text-foreground rounded-lg border-0 focus:outline-none focus:ring-2 focus:ring-primary resize-none max-h-24"
            rows="1"
          />

          {/* Send Button */}
          <button
            onClick={handleSend}
            disabled={isSending || (!text.trim() && !attachment)}
            className="p-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}

export default ChatWindow;
