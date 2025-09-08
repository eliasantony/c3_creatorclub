/*
  Seed script for local development using service account or emulator.
  Usage (emulator):
    export FIRESTORE_EMULATOR_HOST=localhost:8080
    export GCLOUD_PROJECT=c3club-app
    npx ts-node src/scripts/seed.ts
*/
import { initializeApp, cert, ServiceAccount } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import fs from 'node:fs';
import path from 'node:path';

// Prefer explicit service account for production seeding
function initAdmin() {
  const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.SERVICE_ACCOUNT_PATH;
  if (saPath && fs.existsSync(saPath)) {
    const abs = path.resolve(saPath);
    const svc = JSON.parse(fs.readFileSync(abs, 'utf8')) as ServiceAccount & { project_id?: string };
    if (!process.env.GCLOUD_PROJECT && svc.project_id) {
      process.env.GCLOUD_PROJECT = svc.project_id;
    }
    console.log(`Initializing with service account at ${abs} (project: ${process.env.GCLOUD_PROJECT})`);
    initializeApp({ credential: cert(svc) });
  } else {
    if (!process.env.GCLOUD_PROJECT) {
      process.env.GCLOUD_PROJECT = 'c3club-app';
    }
    console.log('Initializing with Application Default Credentials');
    initializeApp();
  }
}

initAdmin();
const db = getFirestore();

async function seedGroups() {
  const groups: { id: string; name: string; type: 'community' | 'private' }[] = [
    { id: 'photographers', name: 'Photographers', type: 'community' },
    { id: 'videographers', name: 'Videographers', type: 'community' },
    { id: 'web-developers', name: 'Web Developers', type: 'community' },
  ];
  for (const g of groups) {
    const ref = db.collection('groups').doc(g.id);
    await ref.set(
      {
        name: g.name,
        type: g.type,
        ownerId: 'system',
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
  console.log(`Seeded groups: ${groups.map((g) => g.id).join(', ')}`);
}

async function seedRooms() {
  const rooms = [
    {
      id: 'sample1',
      name: 'Podcast Studio – Neubau',
      description:
        'Cozy podcast studio with top-notch acoustic treatment and recording equipment.',
      neighborhood: 'Neubau',
      capacity: 3,
      facilities: ['podcast', 'acoustic', 'mic x3', 'wifi'],
      photos: [
        'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1516387938699-a93567ec168e?q=80&w=1400&auto=format&fit=crop',
      ],
      openHourStart: 6,
      openHourEnd: 23,
      priceCents: 6900,
      rating: 4.8,
    },
    {
      id: 'sample2',
      name: 'Daylight Photo Loft – Leopoldstadt',
      description:
        'Bright and spacious photo loft with large windows and natural light.',
      neighborhood: 'Leopoldstadt',
      capacity: 4,
      facilities: ['lighting', 'backdrops', 'tripod', 'wifi'],
      photos: [
        'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1400&auto=format&fit=crop',
      ],
      openHourStart: 6,
      openHourEnd: 23,
      priceCents: 9900,
      rating: 4.6,
    },
    {
      id: 'sample3',
      name: 'Meeting Room – Mariahilf',
      description:
        'Spacious meeting room equipped with a screen, whiteboard, and coffee station.',
      neighborhood: 'Mariahilf',
      capacity: 6,
      facilities: ['screen', 'whiteboard', 'coffee', 'wifi'],
      photos: [
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1524758631624-e2822e304c36?q=80&w=1400&auto=format&fit=crop',
      ],
      openHourStart: 6,
      openHourEnd: 23,
      priceCents: 5900,
      rating: 4.5,
    },
    {
      id: 'sample4',
      name: 'Creator Corner – Wieden',
      description:
        'Creative space with a backdrop, lights, and props for photo shoots.',
      neighborhood: 'Wieden',
      capacity: 2,
      facilities: ['backdrop', 'lights', 'props', 'wifi'],
      photos: [
        'https://images.unsplash.com/photo-1520880867055-1e30d1cb001c?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1520880867055-1e30d1cb001c?q=80&w=1400&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1520880867055-1e30d1cb001c?q=80&w=1400&auto=format&fit=crop',
      ],
      openHourStart: 6,
      openHourEnd: 23,
      priceCents: 4900,
      rating: 4.4,
    },
  ];

  for (const r of rooms) {
    await db.collection('rooms').doc(r.id).set(r);
  }
  console.log('Seeded rooms');
}

async function main() {
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log(`Using Firestore Emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`);
  } else {
    console.log(`Using Firestore project ${process.env.GCLOUD_PROJECT}`);
  }
  await seedGroups();
  await seedRooms();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
