defmodule EpicenterWeb.StyleguideData do
  def generate_address_data() do
    for street <- ["Park", "Main", "Oak", "Pine", "Maple"],
        street_type <- ["Ave", "Blvd", "St", "Way"],
        city <- ["Washington", "Arlington", "Centerville", "Springfield", "Georgetown", "Fairview"],
        state <- ["CA", "NY", "OH", "OR", "WA"] do
      "#{Enum.random(100..170)} #{street} #{street_type}, #{city}, #{state} #{Enum.random(10000..99999)}"
    end
    |> Enum.sort()
  end
end
