# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_metaldetecting — Activities

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:buy-detector @cat:activities
  Scenario: Buy metal detector at shop
    """
    Checklist test: At the priest ped (-1111.29,-1689.21,3.38) target 'Open Metal Detector Shop'; buy detector for $500 via cash or card.
    """
    Given my cash balance is at least 500
    When I manually: go to the priest ped at the Vespucci beach metal detector shop
    And I select the "Open Metal Detector Shop" target option
    Then the "qbmetaldetecting:shop" app opens
    When I manually: buy the metal detector for $500 using cash or card
    Then I should see a notification containing "Metal detector purchased."
    And I should have 1 "metaldetector"
    And I confirm: $500 is deducted from my cash or bank

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:shop-blip-ped @cat:activities @manual
  Scenario: Shop blip and ped
    """
    Checklist test: Check map for 'Metal Detector Shop' blip at Vespucci beach and that the priest ped spawns at the shop.
    """
    When I manually: open the map and look at Vespucci beach
    Then I confirm: a 'Metal Detector Shop' blip is shown at Vespucci beach
    When I manually: go to the Metal Detector Shop
    Then I confirm: the priest ped is spawned at the shop

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:use-detector @cat:activities
  Scenario: Use detector item to start detecting
    """
    Checklist test: Use the metaldetector item from inventory; detector prop attaches, walking anim plays, textUI shows ground status.
    """
    Given I have 1 "metaldetector"
    When I use the "metaldetector"
    Then I confirm: the detector prop is attached to my character
    And I confirm: a walking animation plays
    And I confirm: the text UI shows the ground status

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:ground-check @cat:activities
  Scenario: Ground suitability text
    """
    Checklist test: While detecting walk on sand/dirt vs road; text switches between 'Suitable ground' and 'unsuitable'; timer only counts on valid ground.
    """
    Given I have 1 "metaldetector"
    When I use the "metaldetector"
    And I manually: walk on sand or dirt
    Then the text UI should show "Suitable ground"
    And I confirm: the timer counts while I am on suitable ground
    When I manually: walk onto a road
    Then the text UI should show "unsuitable"
    And I confirm: the timer does not count on unsuitable ground

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:find-minigame @cat:activities
  Scenario: Find alert, skillbar and dig
    """
    Checklist test: After the cooldown 'You may have found something' appears; pass the skillbar; dig animation plays and loot is received.
    """
    Given I have 1 "metaldetector"
    When I use the "metaldetector"
    And I manually: walk on suitable ground until the find cooldown ends
    Then I should see a notification containing "You may have found something."
    When I manually: pass the skillbar
    Then I confirm: the dig animation plays
    And I confirm: I receive loot

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:loot-skill-xp @cat:activities
  Scenario: Loot and metaldetecting XP
    """
    Checklist test: Complete finds; items from loot list are added (clump, scrap, copper...), XP awarded and 'level reached' notice on level up.
    """
    Given I have 1 "metaldetector"
    When I use the "metaldetector"
    And I manually: complete several finds on suitable ground
    Then I confirm: items from the loot list (clump, scrap, copper...) are added to my inventory
    And I confirm: I am awarded metaldetecting XP
    And I confirm: a 'Metal detecting level' reached notice appears on level up

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:level-gated-loot @cat:activities
  Scenario: Level-gated loot and cooldown
    """
    Checklist test: At low level only low-tier loot drops; find cooldown shrinks from 55s toward 5s as level rises.
    """
    Given I have 1 "metaldetector"
    When I use the "metaldetector"
    And I manually: complete several finds at a low level
    Then I confirm: only low-tier loot drops
    And I confirm: the find cooldown starts at about 55s and shrinks toward 5s as my level rises

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:stop-detecting @cat:activities
  Scenario: Stop by reusing item
    """
    Checklist test: Use the detector item again while active; detecting stops, prop removed, animation cleared.
    """
    Given I have 1 "metaldetector"
    When I use the "metaldetector"
    And I use the "metaldetector"
    Then I confirm: detecting stops
    And I confirm: the detector prop is removed
    And I confirm: the animation is cleared

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:stop-in-vehicle @cat:activities
  Scenario: Cannot detect in vehicle
    """
    Checklist test: Use detector while in a vehicle (refused), and enter a vehicle while detecting (stops with notice).
    """
    Given I have 1 "metaldetector"
    And I am in the driver seat of a "test_car"
    When I use the "metaldetector"
    Then I should see a notification containing "You cannot use a metal detector in a vehicle."
    When I get out of the vehicle
    And I use the "metaldetector"
    And I get in the vehicle
    Then I should see a notification containing "Metal detecting stopped in a vehicle."

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:stop-on-death @cat:activities @needs:admin
  Scenario: Detecting stops on death
    """
    Checklist test: Die while detecting; detecting stops, prop is removed and the active state resets.
    """
    Given I have 1 "metaldetector"
    When I use the "metaldetector"
    And I run the command "/kill"
    Then I should be dead
    And I confirm: detecting stops and the detector prop is removed
    And I confirm: the active detecting state is reset

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:wash-clump @cat:activities
  Scenario: Wash metal clump
    """
    Checklist test: Hold a clump and use the 'Wash metal clump' target at a wash spot near (-1250,-1541,4.3); pass skillbar + 5s progress.
    """
    Given I have 1 "clump"
    When I manually: go to a wash spot near the water at the beach
    And I select the "Wash metal clump" target option
    And I manually: pass the skillbar
    Then a progress bar should run
    When I wait 5 seconds
    Then I should see a notification containing "You washed the clump and found"
    And my "clump" count should have changed by -1

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:wash-no-clump @cat:activities
  Scenario: Wash without clump refused
    """
    Checklist test: Use a wash spot without a clump; 'You need a clump to wash' error appears.
    """
    Given I have no "clump"
    When I manually: go to a wash spot near the water at the beach
    And I select the "Wash metal clump" target option
    Then I should see a notification containing "You need a clump to wash."
    And I should see an error notification

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:sell-finds @cat:activities
  Scenario: Sell finds to shop
    """
    Checklist test: In the shop Sell tab pick an owned find (ring, coin, bottle cap...), enter amount, sell; money paid at configured value.
    """
    Given I have 1 "antique_coin"
    When I manually: go to the Metal Detector Shop and open it
    Then the "qbmetaldetecting:shop" app should be open
    When I manually: open the Sell tab, pick the antique coin, enter an amount and sell
    Then I should see a notification containing "Sold"
    And I confirm: the money paid matches the configured value

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:catalog-command @cat:activities
  Scenario: Metal detecting catalog
    """
    Checklist test: Run /metaldetectcatalog; panel shows your level, max level, detector and loot table with unlock levels; Escape closes.
    """
    When I run the command "/metaldetectcatalog"
    Then the "qbmetaldetecting:catalog" app opens
    And I confirm: the panel shows my level, max level and detector
    And I confirm: the loot table shows unlock levels
    When I manually: press Escape
    Then I confirm: the panel closes

  @kora_metaldetecting @checklist @checklist:kora_metaldetecting:no-room-handling @cat:activities
  Scenario: Inventory full on find/purchase
    """
    Checklist test: Fill inventory then find loot or buy detector; error shown, purchase refunded.
    """
    Given I have 1 "metaldetector"
    And my cash balance is 500
    When I manually: fill my inventory completely
    And I manually: find loot with the detector
    Then I should see a notification containing "You do not have room for that find."
    When I manually: buy a metal detector at the shop
    Then I should see a notification containing "You do not have room for a metal detector."
    And my cash balance should be 500
