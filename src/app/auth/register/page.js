/**
 * Registration Page
 * 
 * Conditional behavior based on system initialization:
 * - Uninitialized: Shows registration form (creates first super admin)
 * - Initialized: Shows locked message (registration closed)
 */

'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import styles from './register.module.css';

export default function RegisterPage() {
  const router = useRouter();
  const [systemInitialized, setSystemInitialized] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    passwordConfirm: '',
    name: '',
  });
  const [submitting, setSubmitting] = useState(false);

  // Check system initialization status
  useEffect(() => {
    async function checkSystemState() {
      try {
        const res = await fetch('/api/system/state');
        const data = await res.json();
        setSystemInitialized(data.initialized);
      } catch (err) {
        console.error('Error checking system state:', err);
        setSystemInitialized(false); // Default to uninitialized if error
      } finally {
        setLoading(false);
      }
    }

    checkSystemState();
  }, []);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);

    // Validation
    if (!formData.email || !formData.password || !formData.name) {
      setError('All fields are required');
      setSubmitting(false);
      return;
    }

    if (formData.password !== formData.passwordConfirm) {
      setError('Passwords do not match');
      setSubmitting(false);
      return;
    }

    if (formData.password.length < 8) {
      setError('Password must be at least 8 characters');
      setSubmitting(false);
      return;
    }

    try {
      const res = await fetch('/api/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password,
          name: formData.name,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.message || data.error || 'Registration failed');
        setSubmitting(false);
        return;
      }

      // Success - redirect to dashboard
      router.push('/app/dashboard');
    } catch (err) {
      setError('An unexpected error occurred');
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className={styles.container}>
        <div className={styles.card}>
          <p>Loading system status...</p>
        </div>
      </div>
    );
  }

  // System is initialized - registration closed
  if (systemInitialized) {
    return (
      <div className={styles.container}>
        <div className={styles.card}>
          <div className={styles.lockedState}>
            <h1>Registration Closed</h1>
            <p>
              Xhaira is initialized and ready to use. Public registration is no longer available.
            </p>
            <p>
              <strong>To request access:</strong> Contact your Xhaira system administrator.
            </p>
            <a href="/auth/login" className={styles.button}>
              Go to Login
            </a>
          </div>
        </div>
      </div>
    );
  }

  // System not initialized - allow registration (first user setup)
  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h1>Welcome to Xhaira</h1>
        <p className={styles.subtitle}>Create your super administrator account</p>

        {error && <div className={styles.error}>{error}</div>}

        <form onSubmit={handleSubmit} className={styles.form}>
          <div className={styles.formGroup}>
            <label htmlFor="name">Full Name</label>
            <input
              id="name"
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              placeholder="Your name"
              required
            />
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              name="email"
              value={formData.email}
              onChange={handleInputChange}
              placeholder="your@email.com"
              required
            />
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange}
              placeholder="Min 8 characters"
              required
            />
          </div>

          <div className={styles.formGroup}>
            <label htmlFor="passwordConfirm">Confirm Password</label>
            <input
              id="passwordConfirm"
              type="password"
              name="passwordConfirm"
              value={formData.passwordConfirm}
              onChange={handleInputChange}
              placeholder="Confirm password"
              required
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className={styles.submitButton}
          >
            {submitting ? 'Creating account...' : 'Create Account'}
          </button>
        </form>

        <p className={styles.info}>
          You are creating the first administrator account. After registration,
          the system will be initialized and only admins can create new users.
        </p>
      </div>
    </div>
  );
}
