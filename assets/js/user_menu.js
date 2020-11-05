export let UserMenu = {
  setup() {
    document.querySelectorAll("#user-menu").forEach((userMenu) => {
      userMenu.addEventListener("click", (event) => {
        let target = document.querySelector("#user-menu-list");
        target.style.display = target.style.display === "block" ? "none" : "block";
      });
    });

    document.addEventListener("click", (e) => {
      document.querySelectorAll("#user-menu").forEach((userMenu) => {
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
