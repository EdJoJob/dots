
let {commands} = vimfx.modes.normal
vimfx.addCommand({
  name: 'search_tabs',
  description: 'Search tabs',
  category: 'tabs',
  order: commands.focus_location_bar.order + 1,
}, (args) => {
  let {vim} = args
  let {gURLBar} = vim.window
  gURLBar.value = ''
  commands.focus_location_bar.run(args)
  // Change the `*` on the text line to a `%` to search tabs instead of bookmarks.
  gURLBar.value = '% '
  gURLBar.onInput(new vim.window.KeyboardEvent('input'))
});

vimfx.addCommand({
    name: "closetabtree",
    description: "Close the current tab tree",
}, ({vim}) => {
    let childTab = null;
    let browser = vim.window.gBrowser;
    while (1) {
        childTab = vim.window.TreeStyleTabService.getFirstChildTab(browser.mCurrentTab);
        if (childTab == null) {
            break;
        }
        browser.removeTab( childTab );
    }
    browser.removeTab( browser.mCurrentTab );
});


vimfx.addCommand({
    name: "closefulltabtree",
    description: "Close the full tab tree from the root",
}, ({vim}) => {
    let browser = vim.window.gBrowser;
    var rootTab = vim.window.TreeStyleTabService.getRootTab(browser.mCurrentTab);
    var childTab;

    if (rootTab == null) {
        rootTab = browser.mCurrentTab;
    }

    while (1) {
        childTab = vim.window.TreeStyleTabService.getFirstChildTab(rootTab);
        if (childTab == null) {
            break;
        }
        browser.removeTab( childTab );
    }
    browser.removeTab( rootTab );
});

