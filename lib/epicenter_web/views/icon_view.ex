defmodule EpicenterWeb.IconView do
  use EpicenterWeb, :view

  def arrow_down_icon(width \\ 20, height \\ 20) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M7.41 8.59003L12 13.17L16.59 8.59003L18 10L12 16L6 10L7.41 8.59003Z" fill="black" fill-opacity="0.87"/>
    </svg>
    """
    |> raw()
  end

  def arrow_right_icon(width, height) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 8 12" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M2.00009 0L0.590088 1.41L5.17009 6L0.590088 10.59L2.00009 12L8.00009 6L2.00009 0Z" fill="#B0B0B0"/>
    </svg>
    """
    |> raw()
  end

  def error_icon(width \\ 16, height \\ 16) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M11 15H13V17H11V15ZM11 7H13V13H11V7ZM11.99 2C6.47 2 2 6.48 2 12C2 17.52 6.47 22 11.99 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 11.99 2ZM12 20C7.58 20 4 16.42 4 12C4 7.58 7.58 4 12 4C16.42 4 20 7.58 20 12C20 16.42 16.42 20 12 20Z" fill="black" fill-opacity="0.87"/>
    </svg>
    """
    |> raw()
  end

  def logo_icon(width \\ 96, height \\ 96) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 96 96" fill="none" xmlns="http://www.w3.org/2000/svg">
      <mask id="mask0" mask-type="alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="96" height="96">
        <circle cx="48.137" cy="48.019" r="45.9172" transform="rotate(2.48248 48.137 48.019)" fill="#4F4F4F"/>
      </mask>
      <g mask="url(#mask0)">
        <rect x="-27.4771" y="-29.9447" width="152.101" height="152.101" transform="rotate(2.48248 -27.4771 -29.9447)" fill="#B9CCF2"/>
        <path d="M33.3788 22.4121L-29.3358 80.7228L110.841 77.4644L73.0436 45.095L70.7612 57.7735L33.3788 22.4121Z" fill="#162033" stroke="#162033" stroke-width="3" stroke-linejoin="round"/>
        <rect x="-26.3755" y="78.6969" width="119.098" height="31.5681" transform="rotate(2.48248 -26.3755 78.6969)" fill="#507CD1"/>
        <path d="M33.0501 22.3864L-29.3355 80.7229L102.553 86.4408L72.7198 45.1649L59.6419 59.2586L33.0501 22.3864Z" fill="#507CD1" stroke="#507CD1" stroke-width="3" stroke-linejoin="round"/>
        <path d="M32.4622 28.4782L18.9657 41.2501L32.1178 39.805L46.7397 48.5022L32.4622 28.4782Z" fill="white" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M72.3206 51.3629L64.3485 59.9653L72.5723 58.511L82.1414 63.3839L72.3206 51.3629Z" fill="white" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      </g>
    </svg>
    """
    |> raw()
  end

  def person_icon(width \\ 20, height \\ 20) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 5C13.66 5 15 6.34 15 8C15 9.66 13.66 11 12 11C10.34 11 9 9.66 9 8C9 6.34 10.34 5 12 5ZM12 19.2C9.5 19.2 7.29 17.92 6 15.98C6.03 13.99 10 12.9 12 12.9C13.99 12.9 17.97 13.99 18 15.98C16.71 17.92 14.5 19.2 12 19.2Z" fill="black" fill-opacity="0.87"/>
    </svg>
    """
    |> raw()
  end

  def phone_icon(width, height) do
    """
    <svg width="#{width}" height="#{height}" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M3.62 7.79C5.06 10.62 7.38 12.93 10.21 14.38L12.41 12.18C12.68 11.91 13.08 11.82 13.43 11.94C14.55 12.31 15.76 12.51 17 12.51C17.55 12.51 18 12.96 18 13.51V17C18 17.55 17.55 18 17 18C7.61 18 0 10.39 0 1C0 0.45 0.45 0 1 0H4.5C5.05 0 5.5 0.45 5.5 1C5.5 2.25 5.7 3.45 6.07 4.57C6.18 4.92 6.1 5.31 5.82 5.59L3.62 7.79Z" fill="white"/>
    </svg>
    """
    |> raw()
  end
end
