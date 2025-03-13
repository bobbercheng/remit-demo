defmodule RemitWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  Provides error handling for controllers that use the action_fallback pattern.
  """
  use RemitWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: RemitWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: RemitWeb.ErrorJSON)
    |> render(:error, message: "Resource not found")
  end

  # This clause handles validation errors
  def call(conn, {:error, message}) when is_binary(message) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: RemitWeb.ErrorJSON)
    |> render(:error, message: message)
  end

  # This clause handles other errors
  def call(conn, {:error, reason}) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: RemitWeb.ErrorJSON)
    |> render(:error, message: "Internal server error", details: inspect(reason))
  end
end 