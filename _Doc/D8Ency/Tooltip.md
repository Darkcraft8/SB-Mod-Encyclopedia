### Information on the addition of tooltip inside of a page

---

#### String
render a tooltip that is scaled to the text,
</br>"tooltip" : string

ex| "tooltip" : "Place An extractor on top of the ore node."

---

#### Item|Ingredient List
open a scripted pane that mimic the ingredients list of the vanilla crafting pane(s)

    "tooltip" : {
            "type" : <String, must be "itemList">,
            "override" : {
                "title" : <String, default to "ITEM">,
                "mimicRecipeTooltip" : <Boolean, Determine if the tooltip should act like the ingredient list of the crafting panes>
            },
            "items" :<String "recipePath" or Table "recipeJson">
        }

    ex| "tooltip" : {
            "type" : "itemList",
            "override" : {
                "title" : "INGREDIENTS",
                "mimicRecipeTooltip" : true
            },
            "items" : "/D8Weaponry/recipe/inventorstable1/d8Weaponry_gunsmithrefinementworkbench.recipe"
        }

---

    