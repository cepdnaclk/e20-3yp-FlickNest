import { initializeApp } from 'firebase/app';
import { getDatabase } from 'firebase/database';

const firebaseConfig = {
  apiKey: "AIzaSyBbLlUeFN9aQW36T9aJdMIs-5J5ZGq9WRc",
  authDomain: "flicknestfirebase.firebaseapp.com",
  databaseURL: "https://flicknestfirebase-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "flicknestfirebase",
  storageBucket: "flicknestfirebase.firebasestorage.app",
  messagingSenderId: "611179071521",
  appId: "1:611179071521:web:1c2bc30b9d93b3ae4f3b60",
  measurementId: "G-CZXZ9LDXZE"
};

const app = initializeApp(firebaseConfig);
export const database = getDatabase(app);
export default app;
