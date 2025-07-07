import { useState, useEffect } from 'react';
import { ref, onValue, off } from 'firebase/database';
import { database } from '../lib/firebase';

export function useFirebaseData(path) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const dataRef = ref(database, path);
    
    const unsubscribe = onValue(dataRef, (snapshot) => {
      try {
        const value = snapshot.val();
        setData(value);
        setLoading(false);
        setError(null);
      } catch (err) {
        setError(err.message);
        setLoading(false);
      }
    }, (error) => {
      setError(error.message);
      setLoading(false);
    });

    return () => {
      off(dataRef);
    };
  }, [path]);

  return { data, loading, error };
}

export function useEnvironmentData(environmentId) {
  return useFirebaseData(`environments/${environmentId}`);
}

export function useSymbolsData() {
  return useFirebaseData('symbols');
}

export function useUsersData() {
  return useFirebaseData('users');
}
