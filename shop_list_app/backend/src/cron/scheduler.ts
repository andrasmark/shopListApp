// import cron from 'node-cron';
// import { startScraping } from '../scraping/scrape';
// import { saveToFirestore } from '../firebase/firestore';

// cron.schedule('0 0 * * *', async () => {
//   console.log('Scheduled scraping started...');
//   const scrapedData = await startScraping();
//   await saveToFirestore(scrapedData);
//   console.log('Scraping completed and saved to Firestore.');
// });

// console.log('Cron job scheduled to run every midnight.');
