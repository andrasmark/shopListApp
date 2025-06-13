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

    //await saveKAUFLANDProductsToFirestore(products);
    console.log("Termékek sikeresen feltöltve a Firestore-ba!");
  } catch (error) {
    console.error("Hiba történt a scraping során KAUFLAND:", error);
  } finally {
    await browser.close();
  }
}

export async function scrapeLidl() {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');

  try {
    await page.goto("https://www.lidl.ro/c/oferte-de-luni/a10073121?channel=store&tabCode=Current_Sales_Week", { waitUntil: "networkidle2" }); // vár az oldal teljes betöltésére

    // Süti elfogadás gomb (ha szükséges)
    // try {
    //   await page.waitForSelector(".cookie-alert-extended-button", { timeout: 10000 });
    //   await page.click(".cookie-alert-extended-button");
    // } catch (error) {
    //   console.log("Nincs süti elfogadás gomb, vagy nem található.");
    // }

    // Görgetés az összes termék betöltéséhez
    await autoScroll(page);
    
    // Várj, amíg a termékek betöltődnek
    await page.waitForSelector(".product-grid-box", { timeout: 10000 });

    // Termékadatok kinyerése
    const products = await page.evaluate(() => {
      const items = document.querySelectorAll(".product-grid-box");
      return Array.from(items).map((product) => {
        const nameElement = product.querySelector(".product-grid-box__title");
        const priceElement = product.querySelector(".ods-price__value");
        const oldPriceElement = product.querySelector(".ods-price__stroke-price");
        const discountElement = product.querySelector(".ods-price__box-content-text-el");
        const imageElement = product.querySelector(".odsc-image-gallery__image");

        return {
          name: nameElement?.textContent?.trim() || "N/A",
          price: priceElement?.textContent?.trim() || "N/A",
          oldPrice: oldPriceElement?.textContent?.trim() || "N/A",
          discount: discountElement?.textContent?.trim() || "N/A",
          image: imageElement?.getAttribute("src") || "N/A",
        };
      });
    });

    console.log("Lekért termékek LIDL:", products);

    await saveLIDLProductsToFirestore(products);
    console.log("Termékek sikeresen feltöltve a Firestore-ba!");
  } catch (error) {
    console.error("Hiba történt a scraping során LIDL:", error);
  } finally {
    await browser.close();
  }
}

async function autoScroll(page: { evaluate: (arg0: () => Promise<void>) => any; }) {
  await page.evaluate(async () => {
    await new Promise<void>((resolve) => {
      let totalHeight = 0;
      const distance = 100;
      const timer = setInterval(() => {
        const scrollHeight = document.body.scrollHeight;
        window.scrollBy(0, distance);
        totalHeight += distance;

        if (totalHeight >= scrollHeight) {
          clearInterval(timer);
          resolve();
        }
      }, 100);
    });
  });
}

export async function scrapeCarrefour() {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

 
  
  await page.setUserAgent('Mozilla/5.0 ...');

  try {
    await page.goto("https://carrefour.ro/", { waitUntil: "networkidle2" });

    await autoScroll(page);
    //await page.waitForSelector(".product-card", { timeout: 10000 });

    const products = await page.evaluate(() => {
       const normalizePrice = (priceStr: string) => {
        if (!priceStr) return 0;
        const cleaned = priceStr
          .replace(/[^0-9\s]/g, "")
          .trim()
          .split(/\s+/);
        if (cleaned.length === 2) {
          return parseFloat(`${cleaned[0]}.${cleaned[1]}`);
        }
        return parseFloat(cleaned[0]) || 0;
      };

      const items = document.querySelectorAll(".productItem");
      return Array.from(items).map((product) => {
        const nameElement = product.querySelector(".productItem-name");
        const priceElement = product.querySelector(".price-final");
        const oldPriceElement = product.querySelector(".price-old");
        const discountElement = null;
        const imageElement = product.querySelector(".product-image-photo");

        //here the discount is calculated because it is not present in the HTML
        const priceRaw = priceElement?.textContent?.trim() || "";
        const oldPriceRaw = oldPriceElement?.textContent?.trim() || "";

        const price = normalizePrice(priceRaw);
        const oldPrice = normalizePrice(oldPriceRaw);

        let discount = null;
        if (oldPrice > 0 && price > 0 && oldPrice > price) {
          const percent = ((oldPrice - price) / oldPrice) * 100;
          discount = `-${percent.toFixed(0)}%`;
        }

        return {
          name: nameElement?.textContent?.trim() || "N/A",
          price: price,
          oldPrice: oldPrice,
          discount: discount,
          image: imageElement?.getAttribute("src") || "N/A",
        };
      });
    });

    console.log("Lekért termékek CARREFOUR:", products);
    await saveCARREFOURProductsToFirestore(products);
  } catch (error) {
    console.error("Hiba történt a scraping során CARREFOUR:", error);
  } finally {
    await browser.close();
  }
}

async function saveCARREFOURProductsToFirestore(products: any[]) {
  const batch = db.batch();
  products.forEach((product) => {
    const productRef = db.collection("productsCarrefour").doc();

    // const price = parseFloat(product.price.replace(',', '.')) || 0;
    // const oldPrice = parseFloat(product.oldPrice.replace(',', '.')) || 0;

    batch.set(productRef, {
      productName: product.name,
      productPrice: product.price,
      productOldPrice: product.oldPrice,
      productDiscount: product.discount,
      productImage: product.image,
    });
  });
  await batch.commit();
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
export async function scrapeAuchan() {
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

  await page.setUserAgent('Mozilla/5.0 ...'); // maradhat ugyanaz

  try {
    await page.goto("https://www.auchan.ro/top-deals?page=4", { waitUntil: "networkidle2" });
    await autoScroll(page);
    //await page.waitForSelector(".products__list__item", { timeout: 10000 });

    const products = await page.evaluate(() => {
      const items = document.querySelectorAll(".vtex-search-result-3-x-galleryItem");
      return Array.from(items).map((product) => {
        const nameElement = product.querySelector(".vtex-product-summary-2-x-productBrand ");
        const priceElement = product.querySelector(".vtex-product-price-1-x-currencyContainer--shelfPrice");
        const oldPriceElement = product.querySelector(".vtex-product-price-1-x-listPriceWithUnitMultiplier");
        //const discountElement = product.querySelector(".product__label--discount");
        const imageElement = product.querySelector(".vtex-product-summary-2-x-imageNormal");

        return {
          name: nameElement?.textContent?.trim() || "N/A",
          price: priceElement?.textContent?.trim() || "N/A",
          oldPrice: oldPriceElement?.textContent?.trim() || "N/A",
          //discount: discountElement?.textContent?.trim() || "N/A",
          image: imageElement?.getAttribute("src") || "N/A",
        };
      });
    });

    console.log("Lekért termékek AUCHAN:", products);
    await saveAUCHANProductsToFirestore(products);
  } catch (error) {
    console.error("Hiba történt a scraping során AUCHAN:", error);
  } finally {
    await browser.close();
  }
}

async function saveAUCHANProductsToFirestore(products: any[]) {
  const batch = db.batch();
  products.forEach((product) => {
    const productRef = db.collection("productsAuchan").doc();

    const price = parseFloat(product.price.replace(',', '.')) || 0;
    const oldPrice = parseFloat(product.oldPrice.replace(',', '.')) || 0;

    batch.set(productRef, {
      productName: product.name,
      productPrice: price,
      productOldPrice: oldPrice,
      productDiscount: null, //product.discount,
      productImage: product.image,
    });
  });
  await batch.commit();
}


async function saveKAUFLANDProductsToFirestore(products: any[]) {
  const batch = db.batch();
  products.forEach((product) => {
    const productRef = db.collection("productsKaufland").doc(); // Automatikus ID

    // ar converalasa double-re
    const price = parseFloat(product.price.replace(',', '.')) || 0;
    const oldPrice = parseFloat(product.oldPrice.replace(',', '.')) || 0;

    batch.set(productRef, {
      productDiscount: product.discount,
      productImage: product.image,
      productName: product.name,
      productOldPrice: oldPrice,
      productPrice: price,
      productSubtitle: product.subtitle,
    });
  });
  await batch.commit();
}

async function saveLIDLProductsToFirestore(products: any[]) {
  const batch = db.batch();
  products.forEach((product) => {
    const productRef = db.collection("productsLidl").doc(); // Automatikus ID

    // ar converalasa double-re
    const price = parseFloat(product.price.replace(',', '.')) || 0;
    const oldPrice = parseFloat(product.oldPrice.replace(',', '.')) || 0;

    batch.set(productRef, {
      productName: product.name,
      productPrice: price,
      productOldPrice: oldPrice,
      productDiscount: product.discount,
      productImage: product.image,
    });
  });
  await batch.commit();
}