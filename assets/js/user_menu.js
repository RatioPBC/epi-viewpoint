export let UserMenu = {
  setup() {
    document.querySelectorAll("#user-menu-title").forEach((userMenu) => {
      userMenu.addEventListener("click", (event) => {
        let target = document.querySelector("#user-menu-list");
        target.style.display = "block";
        event.stopPropagation();
      });
    });

    document.addEventListener("click", (e) => {
      document.querySelectorAll("#user-menu-list").forEach((userMenu) => {
        if (!userMenu.contains(e.target)) {
          document.querySelectorAll("[role=menu]").forEach((menu) => {
            if (menu.style.display === "block") {
              menu.style.display = "none";
            }
          });
        }
      });
    });
  }
};
