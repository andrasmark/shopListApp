import express from "express";
import { scrapeCarrefour, scrapeKaufland, scrapeLidl, scrapeAuchan } from './scraping/scrape';

const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
    res.send("Hello, world!");  
  });

app.get("/scrape", async (req, res) => {
  try {
    console.log("Adatok lekérése folyamatban... KAUFLAND");
    await scrapeKaufland();
    console.log("KAUFLAND scraping kész");
  } catch (error) {
    console.error("KAUFLAND - Hiba az adatlekérésben:", error);
  }
  
  try {
    console.log("Adatok lekérése folyamatban... CARREFOUR");
    await scrapeCarrefour();
    console.log("CARREFOUR scraping kész");
  } catch (error) {
    console.error("CARREFOUR - Hiba az adatlekérésben:", error);
  }
 
  try {
    console.log("Adatok lekérése folyamatban... LIDL");
    await scrapeLidl();
    console.log("LIDL scraping kész");
  }catch (error) {
    console.error("LIDL - Hiba az adatlekérésben:", error);
  }
  
  try {
    console.log("Adatok lekérése folyamatban... AUCHAN");
    await scrapeAuchan();
    console.log("AUCHAN scraping kész");
  } catch (error) {
    console.error("AUCHAN - Hiba az adatlekérésben:", error);
  }
  

  res.send("Scraping kész! Nézd meg a konzolt.");
  console.log("Scraping kész!");
});

app.get("/api/products", (req, res) => {
    res.json({ message: "This is the products route" });
  });

app.listen(PORT, () => {
  console.log(`Szerver fut: http://localhost:${PORT}`);
});

if (require.main === module) {
  const arg = process.argv[2];
  if (arg === 'scrape') {
    (async () => {
      console.log("CLI scraping indul...");
      await Promise.allSettled([
        scrapeKaufland().catch(err => console.error("Kaufland:", err)),
        scrapeCarrefour().catch(err => console.error("Carrefour:", err)),
        scrapeLidl().catch(err => console.error("Lidl:", err)),
        scrapeAuchan().catch(err => console.error("Auchan:", err)),
      ]);
      console.log("CLI scraping befejeződött.");
      process.exit(0);
    })();
  }
}


