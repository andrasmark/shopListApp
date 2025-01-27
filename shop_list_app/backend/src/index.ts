import express from "express";
import { scrapeCarrefour, scrapeKaufland, scrapeLidl } from './scraping/scrape';

const app = express();
const PORT = process.env.PORT || 3000;

// Alapértelmezett route
app.get("/", (req, res) => {
    res.send("Hello, world!");  // Válasz küldése a gyökérre
  });

app.get("/scrape", async (req, res) => {
  console.log("Adatok lekérése folyamatban... KAUFLAND");
  await scrapeKaufland();
  
  console.log("Adatok lekérése folyamatban... CARREFOUR");
  await scrapeCarrefour();
  
  console.log("Adatok lekérése folyamatban... LIDL");
  await scrapeLidl();
  res.send("Scraping kész! Nézd meg a konzolt.");

});

app.get("/api/products", (req, res) => {
    res.json({ message: "This is the products route" });
  });

app.listen(PORT, () => {
  console.log(`Szerver fut: http://localhost:${PORT}`);
});
