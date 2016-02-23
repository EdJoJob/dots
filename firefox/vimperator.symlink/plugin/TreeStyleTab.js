let PLUGIN_INFO = xml`
<VimperatorPlugin>
  <name>Tree Style Tab (vimperaton plugin)</name>
  <description>Vimerator commands for Tree Style Tab</description>
  <version>1.0.1</version>
  <author email="trent-tst@sillyfrog.com">Trent</author>
  <license href="http://opensource.org/licenses/mit-license.php">MIT</license>
  <minVersion>2.3pre</minVersion>
  <detail><![CDATA[
    == Usage ==
      :closstabtree
      :closefulltabtree
  ]]></detail>
</VimperatorPlugin>`;


liberator.modules.commands.addUserCommand(["testtab"], "Test messing with tabs", function(arg1, arg2) {
    TreeStyleTabService.readyToOpenChildTab(gBrowser.selectedTab);
    gBrowser.addTab('http://nbb.co/?xx-' + arg1 + '--' + arg2);
});

liberator.modules.commands.addUserCommand(["closetabtree"], "Close the current tab tree", function() {
    var childTab;
    while (1) {
        childTab = TreeStyleTabService.getFirstChildTab(getBrowser().selectedTab);
        if (childTab == null) {
            break;
        }
        getBrowser().removeTab( childTab );
    }
    getBrowser().removeTab( getBrowser().selectedTab );
});

liberator.modules.commands.addUserCommand(["closefulltabtree"], "Close the full tab tree from the root", function() {
    var rootTab = TreeStyleTabService.getRootTab(getBrowser().selectedTab);
    var childTab;

    if (rootTab == null) {
        rootTab = getBrowser().selectedTab;
    }

    while (1) {
        childTab = TreeStyleTabService.getFirstChildTab(rootTab);
        if (childTab == null) {
            break;
        }
        getBrowser().removeTab( childTab );
    }
    getBrowser().removeTab( rootTab );
});


/* vim:se sts=4 sw=4 et: */
