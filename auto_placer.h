#pragma once

#include <iostream>
#include <cstdlib>
#include <ctime>

#include "field.h"
#include "ship_manager.h"

class AutoPlacer
{
public:
    explicit AutoPlacer(Field *new_field, ShipManager *new_ship_manager);

    void place();

private:
    Field *field;
    ShipManager *ship_manager;
};