defmodule Overflow.Utils.HtmlSanitizer do
  @moduledoc """
  HTML sanitization utilities using Floki.

  Provides functions to sanitize HTML content, removing dangerous elements
  and attributes while preserving safe formatting.
  """

  @doc """
  Sanitizes HTML content by removing dangerous elements and attributes.

  ## Examples

      iex> Overflow.Utils.HtmlSanitizer.sanitize("<p>Hello <script>alert('xss')</script>world</p>")
      "<p>Hello world</p>"

      iex> Overflow.Utils.HtmlSanitizer.sanitize("<p onclick='alert()'>Click me</p>")
      "<p>Click me</p>"
  """
  @spec sanitize(String.t()) :: String.t()
  def sanitize(html) when is_binary(html) do
    html
    |> Floki.parse_document!()
    |> remove_dangerous_elements()
    |> remove_dangerous_attributes()
    |> Floki.raw_html()
  end

  @doc """
  Strips all HTML tags and returns only the text content.

  ## Examples

      iex> Overflow.Utils.HtmlSanitizer.strip_tags("<p>Hello <strong>world</strong></p>")
      "Hello world"
  """
  @spec strip_tags(String.t()) :: String.t()
  def strip_tags(html) when is_binary(html) do
    html
    |> Floki.parse_document!()
    |> Floki.text()
  end

  @doc """
  Sanitizes HTML but only allows specific safe tags.

  ## Examples

      iex> allowed_tags = ["p", "strong", "em", "a"]
      iex> Overflow.Utils.HtmlSanitizer.whitelist("<p>Hello <script>alert('xss')</script><strong>world</strong></p>", allowed_tags)
      "<p>Hello <strong>world</strong></p>"
  """
  @spec whitelist(String.t(), list(String.t())) :: String.t()
  def whitelist(html, allowed_tags) when is_binary(html) and is_list(allowed_tags) do
    html
    |> Floki.parse_document!()
    |> remove_tags_except(allowed_tags)
    |> remove_dangerous_attributes()
    |> Floki.raw_html()
  end

  # Private functions

  # List of dangerous HTML elements that should be removed
  @dangerous_elements [
    "script",
    "style",
    "iframe",
    "object",
    "embed",
    "form",
    "input",
    "button",
    "textarea",
    "select",
    "option",
    "link",
    "meta",
    "base",
    "title",
    "head",
    "frameset",
    "frame",
    "noframes",
    "applet",
    "canvas",
    "audio",
    "video"
  ]

  # List of dangerous attributes that should be removed
  @dangerous_attributes [
    "onclick",
    "onload",
    "onerror",
    "onmouseover",
    "onmouseout",
    "onfocus",
    "onblur",
    "onchange",
    "onsubmit",
    "onreset",
    "onselect",
    "onkeydown",
    "onkeyup",
    "onkeypress",
    "javascript:",
    "vbscript:",
    "data:",
    "about:",
    "mocha:",
    "livescript:"
  ]

  # Safe attributes that are allowed
  @safe_attributes [
    "href",
    "title",
    "alt",
    "src",
    "width",
    "height",
    "class",
    "id",
    "style",
    "target",
    "rel",
    "type",
    "name",
    "value"
  ]

  defp remove_dangerous_elements(document) do
    Enum.reduce(@dangerous_elements, document, fn element, acc ->
      Floki.filter_out(acc, element)
    end)
  end

  defp remove_tags_except(document, allowed_tags) do
    # Get all unique tag names in the document
    all_tags =
      document
      |> Floki.find("*")
      |> Enum.map(fn {tag, _attrs, _children} -> tag end)
      |> Enum.uniq()

    # Remove tags that are not in the allowed list
    tags_to_remove = all_tags -- allowed_tags

    Enum.reduce(tags_to_remove, document, fn tag, acc ->
      # Replace the tag with its text content
      Floki.traverse_and_update(acc, fn
        {^tag, _attrs, children} ->
          children |> Floki.text()

        other ->
          other
      end)
    end)
  end

  defp remove_dangerous_attributes(document) do
    Floki.traverse_and_update(document, fn
      {tag, attrs, children} ->
        safe_attrs = filter_safe_attributes(attrs)
        {tag, safe_attrs, children}

      other ->
        other
    end)
  end

  defp filter_safe_attributes(attrs) do
    Enum.filter(attrs, fn {attr_name, attr_value} ->
      # Allow safe attributes
      # Block dangerous attribute values (like javascript:)
      attr_name in @safe_attributes and
        not has_dangerous_content?(attr_value)
    end)
  end

  defp has_dangerous_content?(value) when is_binary(value) do
    value_lower = String.downcase(value)

    Enum.any?(@dangerous_attributes, fn dangerous ->
      String.contains?(value_lower, dangerous)
    end)
  end

  defp has_dangerous_content?(_), do: false
end
