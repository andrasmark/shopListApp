// import admin from 'firebase-admin';
// import fs from 'fs';

// const serviceAccount = JSON.parse(fs.readFileSync(process.env.FIREBASE_CREDENTIALS || '', 'utf8'));

// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

// const db = admin.firestore();

// interface Product {
//   name: string;
//   price: string;
//   image: string;
// }

// export async function saveToFirestore(products: Product[]): Promise<void> {
//   const batch = db.batch();
//   products.forEach(product => {
//     const docRef = db.collection('products').doc();
//     batch.set(docRef, product);
//   });
//   await batch.commit();
//   console.log('Data saved to Firestore');
// }
