import puppeteer from "puppeteer";
import axios from "axios";
import cheerio from "cheerio";
// import { db } from "./firebase";

export async function scrapeKaufland() {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

  try {
    await page.goto(
      "https://www.kaufland.ro/oferte/oferte-saptamanale/saptamana-curenta.category=01_Carne__mezeluri.html"
    );

    // Süti elfogadás gomb
    // await page.waitForSelector(".cookie-alert-extended-button", { timeout: 60000 });
    // await page.click(".cookie-alert-extended-button");

    // Termékadatok kinyerése
    const products = await page.evaluate(() => {
    //   const items = document.querySelectorAll(".m-offer-tile");
      const items = document.querySelectorAll(".k-product-grid");
      return Array.from(items).map((product) => {
        const nameElement = product.querySelector(".k-product-tile__subtitle");
        const priceElement = product.querySelector(".k-price-tag__price");
        const imageElement = product.querySelector(".k-product-tile__image");

        return {
          name: nameElement?.textContent?.trim() || "N/A",
          price: priceElement?.textContent?.trim() || "N/A",
          image: imageElement?.getAttribute("data-src") || "N/A",
        };
      });
    });

    console.log("Lekért termékek KAUFLAND:", products);
  } catch (error) {
    console.error("Hiba történt a scraping során KAUFLAND:", error);
  } finally {
    await browser.close();
  }
}

export async function scrapeCarrefour() {
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
  
    try {
      await page.goto("https://www.carrefour.ro");
  
      // Süti elfogadás gomb
    //   await page.waitForSelector(".cookie-notice-button", { timeout: 60000 });
    //   await page.click(".cookie-notice-button");
  
      // Termékadatok kinyerése
      const products = await page.evaluate(() => {
        const items = document.querySelectorAll(".productItem");
        return Array.from(items).map((product) => {
          const nameElement = product.querySelector(".productItem-name");
          const priceElement = product.querySelector(".productItem-price");
          const imageElement = product.querySelector(".productItem-image");
  
          return {
            name: nameElement?.textContent?.trim() || "N/A",
            price: priceElement?.textContent?.trim() || "N/A",
            image: imageElement?.getAttribute("src") || "N/A",
          };
        });
      });
  
      console.log("Lekért termékek CARREFOUR:", products);
    } catch (error) {
      console.error("Hiba történt a scraping során CARREFOUR:", error);
    } finally {
      await browser.close();
    }
  }
  
  export async function scrapeLidl() {
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
  
    try {
      await page.goto("https://www.lidl.ro");
  
      // Süti elfogadás gomb
    //   await page.waitForSelector(".cookie-alert-extended-button", { timeout: 60000 });
    //   await page.click(".cookie-alert-extended-button");
  
      // Termékadatok kinyerése
      const products = await page.evaluate(() => {
        const items = document.querySelectorAll(".product-grid-box");
        return Array.from(items).map((product) => {
          const nameElement = product.querySelector("product-grid-box__title");
          const priceElement = product.querySelector(".m-price");
          const imageElement = product.querySelector(".ods-image-gallery");
  
          return {
            name: nameElement?.textContent?.trim() || "N/A",
            price: priceElement?.textContent?.trim() || "N/A",
            image: imageElement?.getAttribute("srcset")?.split(" ")[0] || "N/A",
          };
        });
      });
  
      console.log("Lekért termékek LIDL:", products);
    } catch (error) {
      console.error("Hiba történt a scraping során LIDL:", error);
    } finally {
      await browser.close();
    }
  }

  // Termékek mentése Firestore-ba
// async function saveProductsToFirestore(products: any[]) {
//   const batch = db.batch();
//   products.forEach((product) => {
//     const productRef = db.collection("products").doc(); // Automatikus ID
//     batch.set(productRef, product);
//   });
//   await batch.commit();
// }

// // Scrape és mentés
// async function scrapeAndSave() {
//   const products = await scrapeLidlProducts();
//   await saveProductsToFirestore(products);
//   console.log("Termékek sikeresen feltöltve!");
// }

// scrapeAndSave();
