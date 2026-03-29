'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';

export default function SplashScreen({ onFinished }) {
  const [fadeOut, setFadeOut] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setFadeOut(true), 1800);
    const done = setTimeout(() => onFinished(), 2400);
    return () => { clearTimeout(timer); clearTimeout(done); };
  }, [onFinished]);

  return (
    <div
      className={`fixed inset-0 z-[9999] flex flex-col items-center justify-between bg-[#0f172a] transition-opacity duration-500 ${fadeOut ? 'opacity-0' : 'opacity-100'}`}
    >
      {/* Top spacer */}
      <div />

      {/* Center logo + name */}
      <div className="flex flex-col items-center gap-4 animate-[fadeInUp_0.6s_ease-out]">
        <Image
          src="/Xhaira.png"
          alt="Xhaira"
          width={120}
          height={120}
          priority
          className="drop-shadow-2xl"
        />
        <h1 className="text-white text-3xl font-bold tracking-wide">JETON</h1>
      </div>

      {/* Bottom branding — WhatsApp style */}
      <div className="flex flex-col items-center gap-1 pb-12 animate-[fadeIn_1s_ease-out_0.3s_both]">
        <span className="text-slate-400 text-xs font-medium tracking-widest uppercase">from</span>
        <span className="text-white text-sm font-semibold tracking-wider">XHENVOLT</span>
      </div>
    </div>
  );
}
