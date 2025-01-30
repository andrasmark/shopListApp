//EZ NEM BIZTOS HOGY KELL

// import admin from "firebase-admin";
// import { Request, Response, NextFunction } from "express";

// export async function verifyFirebaseToken(req: Request, res: Response, next: NextFunction) {
//   const token = req.headers.authorization?.split(" ")[1]; // "Bearer token"
//   if (!token) {
//     return res.status(401).send("No token provided");
//   }

//   try {
//     const decodedToken = await admin.auth().verifyIdToken(token);
//     req.user = decodedToken; // req.user tartalmazza a Firebase user infókat
//     next();
//   } catch (error) {
//     return res.status(401).send("Invalid token");
//   }
// }
