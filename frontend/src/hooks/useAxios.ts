import { useState, useCallback } from "react";
import axios, { AxiosRequestConfig } from "axios";

interface UseAxiosResult<T = any> {
  data: T | null;
  loading: boolean;
  error: any;
  sendRequest: (config: AxiosRequestConfig) => Promise<void>;
}

export function useAxios<T = any>(): UseAxiosResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<any>(null);

  const sendRequest = useCallback(async (config: AxiosRequestConfig) => {
    setLoading(true);
    setError(null);
    try {
      const token = localStorage.getItem("token");
      const headers = {
        ...config.headers,
        Authorization: token ? `Bearer ${token}` : undefined,
      };
      const response = await axios({ ...config, headers });
      setData(response.data);
    } catch (err: any) {
      setError(err);
    } finally {
      setLoading(false);
    }
  }, []);

  return { data, loading, error, sendRequest };
}
