/* eslint-disable @typescript-eslint/no-explicit-any */
import { useState, useCallback } from "react";
import axios, { AxiosRequestConfig } from "axios";

const useAxios = <T>() => {
  const [loading, setLoading] = useState<boolean>(false);
  const [getLoading, setGetLoading] = useState<boolean>(false);
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);

  const getToken = (): string | null => {
    return localStorage.getItem("token");
  };

  const request = useCallback(
    async (
      url: string,
      method: "GET" | "POST" | "PUT" | "DELETE" | "PATCH",
      body?: any,
      config?: AxiosRequestConfig,
    ) => {
      // Reset states at the start of each request
      setError(null);
      setData(null);

      if (method === "GET") {
        setGetLoading(true);
      } else {
        setLoading(true);
      }

      const token = getToken();

      const headers = {
        Authorization: token ? `Bearer ${token}` : "",
        ...config?.headers,
      };

      try {
        const baseUrl =
          process.env.NEXT_PUBLIC_BASE_URL || "http://localhost:9090";

        const response = await axios({
          url: `${baseUrl}/${url}`,
          method,
          data: body,
          headers,
          ...config,
        });
        setData(response.data);

        return response.data;
      } catch (err: any) {
        const errorMessage =
          err.response?.data?.errors?.[0]?.message ||
          err.response?.data?.message ||
          err.message ||
          "An error occurred";

        if (err.response?.data?.errors?.[0]?.code === "12004") {
          if (localStorage.getItem("token")) {
            alert("You have been logged out due to inactivity");
          }

          localStorage.removeItem("token");
          localStorage.removeItem("name");
          localStorage.removeItem("email");
          localStorage.removeItem("userId");

          window.location.replace("/");
        }
        setError(errorMessage);
        // Create a new error with the message attached
        const apiError = new Error(errorMessage);
        (apiError as any).response = err.response;
        throw apiError;
      } finally {
        if (method === "GET") {
          setGetLoading(false);
        } else {
          setLoading(false);
        }
      }
    },
    [],
  );

  const get = useCallback(
    (url: string, config?: AxiosRequestConfig) => {
      return request(url, "GET", null, config);
    },
    [request],
  );

  const post = useCallback(
    (url: string, body: any, config?: AxiosRequestConfig) => {
      return request(url, "POST", body, config);
    },
    [request],
  );

  const put = useCallback(
    (url: string, body: any, config?: AxiosRequestConfig) => {
      return request(url, "PUT", body, config);
    },
    [request],
  );

  const patch = useCallback(
    (url: string, body: any, config?: AxiosRequestConfig) => {
      return request(url, "PATCH", body, config);
    },
    [request],
  );

  const softDelete = useCallback(
    (url: string, config?: AxiosRequestConfig) => {
      return request(url, "DELETE", null, config);
    },
    [request],
  );

  return {
    data,
    loading,
    error,
    get,
    post,
    put,
    softDelete,
    patch,
    getLoading,
  };
};

export default useAxios;
