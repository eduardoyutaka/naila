module Catalyst::ComboboxHelper
  # Renders a combobox (autocomplete) input.
  #
  #   catalyst_combobox(name: "basin_id", options: @basins.map { |b| [b.name, b.id] }, placeholder: "Buscar bacia...")
  def catalyst_combobox(name:, options: [], selected: nil, placeholder: nil, **opts)
    wrapper_id = "combobox-#{name.parameterize}-#{SecureRandom.hex(3)}"

    tag.div(data: { controller: "shared--combobox" }, class: opts.delete(:class)) do
      safe_join([
        # Visible text input
        tag.span(class: CatalystFormBuilder::INPUT_WRAPPER, data: { slot: "control" }) {
          tag.input(
            type: "text",
            placeholder: placeholder,
            autocomplete: "off",
            value: options.find { |text, val| val.to_s == selected.to_s }&.first,
            class: CatalystFormBuilder::INPUT_CLASSES,
            data: {
              shared__combobox_target: "input",
              action: "input->shared--combobox#filter keydown->shared--combobox#keydown focus->shared--combobox#open",
            },
          )
        },
        # Hidden field for form submission
        tag.input(type: "hidden", name: name, value: selected, data: { shared__combobox_target: "hidden" }),
        # Popover options list
        tag.div(
          popover: "",
          role: "listbox",
          class: "w-full rounded-xl bg-white/75 p-1 shadow-lg ring-1 ring-zinc-950/10 backdrop-blur-xl dark:bg-zinc-800/75 dark:ring-white/10",
          data: { shared__combobox_target: "list" },
        ) {
          safe_join(options.map { |text, val|
            tag.div(
              text,
              role: "option",
              class: "cursor-default rounded-lg px-3 py-1.5 text-sm text-zinc-950 hover:bg-blue-500 hover:text-white dark:text-white",
              data: { value: val, shared__combobox_target: "option", action: "click->shared--combobox#select" },
            )
          })
        },
      ])
    end
  end
end
