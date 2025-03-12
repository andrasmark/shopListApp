import puppeteer from "puppeteer";
import axios from "axios";
import cheerio from "cheerio";
import { db } from "../firebase/firestore";

export async function scrapeKaufland() {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

  // User agent beállítása
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');

  try {
    await page.goto(
      "https://www.kaufland.ro/oferte/oferte-saptamanale/saptamana-curenta.category=01_Carne__mezeluri.html"
    );

    // Termékadatok kinyerése
    const products = await page.evaluate(() => {
      const items = document.querySelectorAll(".k-product-grid__item");
      return Array.from(items).map((product) => {
        const nameElement = product.querySelector(".k-product-tile__title");
        const subtitleElement = product.querySelector(".k-product-tile__subtitle");
        const priceElement = product.querySelector(".k-price-tag__price");
        const oldPriceElement = product.querySelector(".k-price-tag__old-price");
        const discountElement = product.querySelector(".k-price-tag__discount");
        const imageElement = product.querySelector(".k-product-tile__main-image");

        return {
          name: nameElement?.textContent?.trim() || "N/A",
          subtitle: subtitleElement?.textContent?.trim() || "N/A",
          price: priceElement?.textContent?.trim() || "N/A",
          oldPrice: oldPriceElement?.textContent?.trim() || "N/A",
          discount: discountElement?.textContent?.trim() || "N/A",
          image: imageElement?.getAttribute("src") || "N/A",
        };
      });
    });

    console.log("Lekért termékek KAUFLAND:", products);

    await saveKAUFLANDProductsToFirestore(products);
    console.log("Termékek sikeresen feltöltve a Firestore-ba!");
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
    await page.goto("https://www.lidl.ro", { waitUntil: "networkidle2" });

    // Süti elfogadás gomb (ha szükséges)
    try {
      await page.waitForSelector(".cookie-alert-extended-button", { timeout: 10000 });
      await page.click(".cookie-alert-extended-button");
    } catch (error) {
      console.log("Nincs süti elfogadás gomb, vagy nem található.");
    }

    // Várj, amíg a termékek betöltődnek
    await page.waitForSelector(".product-grid-box", { timeout: 10000 });

    // Termékadatok kinyerése
    const products = await page.evaluate(() => {
      const items = document.querySelectorAll(".product-grid-box");
      return Array.from(items).map((product) => {
        const nameElement = product.querySelector(".product-grid-box__title");
    
        const priceElement = product.querySelector(".m-price");
        const imageElement = product.querySelector(".ods-image-gallery img");

        return {
          name: nameElement?.textContent?.trim() || "N/A",
          price: priceElement?.textContent?.trim() || "N/A",
          image: (imageElement as HTMLImageElement).src || "N/A",
          //image: imageElement?.src || "N/A", // src használata a képhez
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

async function saveKAUFLANDProductsToFirestore(products: any[]) {
  const batch = db.batch();
  products.forEach((product) => {
    const productRef = db.collection("productsKaufland").doc(); // Automatikus ID
    batch.set(productRef, {
      productDiscount: product.discount,
      productImage: product.image,
      productName: product.name,
      productOldPrice: product.oldPrice,
      productPrice: product.price,
      productSubtitle: product.subtitle,
    });
  });
  await batch.commit();
}
