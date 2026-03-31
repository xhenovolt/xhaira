'use client';

import { redirect } from 'next/navigation';
import { useParams } from 'next/navigation';

export default function SystemDetailRedirect() {
  const { id } = useParams();
  redirect(`/app/products/${id}`);
}
