CLASS z2mse_extr3_web_dynpro_comp DEFINITION
  PUBLIC
  INHERITING FROM z2mse_extr3_elements
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS get_instance
      IMPORTING
        element_manager   TYPE REF TO z2mse_extr3_element_manager
      RETURNING
        VALUE(r_instance) TYPE REF TO z2mse_extr3_web_dynpro_comp.
    METHODS add
      IMPORTING
        wdy_component_name    TYPE wdy_component_name
      EXPORTING
        VALUE(is_added)       TYPE abap_bool
        VALUE(new_element_id) TYPE z2mse_extr3_element_manager=>element_id_type.
    METHODS add_component
      IMPORTING
        wdy_component_name    TYPE wdy_component_name
        wdy_controller_name   TYPE wdy_controller_name
      EXPORTING
        VALUE(is_added)       TYPE abap_bool
        VALUE(new_element_id) TYPE z2mse_extr3_element_manager=>element_id_type.
    METHODS wdy_component_name
      IMPORTING
        element_id                TYPE i
      EXPORTING
        VALUE(wdy_component_name) TYPE wdy_component_name.
    METHODS wdy_controller_name
      IMPORTING
        element_id                 TYPE i
      EXPORTING
        VALUE(wdy_component_name)  TYPE wdy_component_name
        VALUE(wdy_controller_name) TYPE wdy_controller_name.
    METHODS make_model REDEFINITION.
    METHODS name REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA instance TYPE REF TO z2mse_extr3_web_dynpro_comp.
    TYPES: BEGIN OF element_type,
             element_id         TYPE z2mse_extr3_element_manager=>element_id_type,
             wdy_component_name TYPE wdy_component_name,
           END OF element_type.
    DATA elements_element_id TYPE HASHED TABLE OF element_type WITH UNIQUE KEY element_id.
    DATA elements_wdy_component_name TYPE HASHED TABLE OF element_type WITH UNIQUE KEY wdy_component_name.
    TYPES: BEGIN OF element_comp_type,
             element_id          TYPE z2mse_extr3_element_manager=>element_id_type,
             wdy_component_name  TYPE wdy_component_name,
             wdy_controller_name TYPE wdy_controller_name,
           END OF element_comp_type.
    DATA elements_comp_element_id TYPE HASHED TABLE OF element_comp_type WITH UNIQUE KEY element_id.
    DATA elements_comp_comp_contr_name TYPE HASHED TABLE OF element_comp_type WITH UNIQUE KEY wdy_component_name wdy_controller_name.
    METHODS _add_component
      IMPORTING
        wdy_component_name    TYPE wdy_component_name
        wdy_controller_name   TYPE wdy_controller_name
      EXPORTING
        VALUE(is_added)       TYPE abap_bool
        VALUE(new_element_id) TYPE z2mse_extr3_element_manager=>element_id_type.
ENDCLASS.



CLASS z2mse_extr3_web_dynpro_comp IMPLEMENTATION.
  METHOD get_instance.
    IF instance IS NOT BOUND.
      CREATE OBJECT instance
        EXPORTING
          i_element_manager = element_manager.
    ENDIF.
    instance->type = web_dynpro_comps_type.
    r_instance = instance.
  ENDMETHOD.

  METHOD add.
    " WDY_COMPONENT
    " WDY_CONTROLLER

    DATA element TYPE element_type.

    READ TABLE elements_wdy_component_name INTO element WITH KEY  wdy_component_name  =  wdy_component_name .
    IF sy-subrc EQ 0.
      is_added = abap_true.
      new_element_id = element-element_id.
    ELSE.

      " Does Web Dynpro Component exists?
      DATA: found_wdy_component_name TYPE wdy_component_name.

      TEST-SEAM wdy_component.
        SELECT SINGLE component_name FROM wdy_component INTO found_wdy_component_name
          WHERE component_name = wdy_component_name
            AND version = 'A'.
      END-TEST-SEAM.

      IF found_wdy_component_name IS NOT INITIAL.
        is_added = abap_true.
      ENDIF.

      IF is_added EQ abap_true.

        new_element_id = element_manager->add_element( element = me ).
        element-element_id = new_element_id.
        element-wdy_component_name = found_wdy_component_name.
        INSERT element INTO TABLE elements_element_id.
        INSERT element INTO TABLE elements_wdy_component_name.

      ENDIF.

      TYPES: BEGIN OF ty_class_component,
               component_name  TYPE wdy_component_name,
               controller_name TYPE wdy_controller_name,
             END OF ty_class_component.
      TYPES ty_class_components TYPE STANDARD TABLE OF ty_class_component WITH KEY component_name controller_name.
      DATA: class_components TYPE ty_class_components,
            class_component  TYPE ty_class_component.

      TEST-SEAM wdy_controller_2.

        SELECT component_name controller_name
          FROM wdy_controller
          INTO CORRESPONDING FIELDS OF TABLE class_components
          WHERE component_name = wdy_component_name
            AND version = 'A'.

      END-TEST-SEAM.

      LOOP AT class_components INTO class_component.

        _add_component( EXPORTING wdy_component_name        = class_component-component_name
                                  wdy_controller_name        = class_component-controller_name ).

      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD _add_component.

    DATA element_comp TYPE element_comp_type.

    READ TABLE elements_comp_comp_contr_name INTO element_comp WITH KEY wdy_component_name  = wdy_component_name
                                                                        wdy_controller_name  = wdy_controller_name .
    IF sy-subrc EQ 0.
      is_added = abap_true.
      new_element_id = element_comp-element_id.
    ELSE.

      " Does component exists?
      DATA: found_component_name  TYPE wdy_component_name,
            found_controller_name TYPE seocmpname.

      TEST-SEAM wdy_controller.
        SELECT SINGLE component_name controller_name FROM wdy_controller
          INTO ( found_component_name, found_controller_name ) WHERE component_name  = wdy_component_name
                                                                 AND controller_name  = wdy_controller_name
                                                                 AND version = 'A'.
      END-TEST-SEAM.

      IF found_component_name IS NOT INITIAL.
        is_added = abap_true.
      ENDIF.

      IF is_added EQ abap_true.

        new_element_id = element_manager->add_element( element = me ).
        element_comp-element_id = new_element_id.
        element_comp-wdy_component_name = found_component_name.
        element_comp-wdy_controller_name = found_controller_name.

        INSERT element_comp INTO TABLE elements_comp_element_id .
        INSERT element_comp INTO TABLE elements_comp_comp_contr_name .

      ENDIF.

    ENDIF.


  ENDMETHOD.

  METHOD add_component.

    add( EXPORTING wdy_component_name = wdy_component_name
         IMPORTING is_added           = is_added ).

    IF is_added EQ abap_true.

      _add_component( EXPORTING wdy_component_name  = wdy_component_name
                                wdy_controller_name = wdy_controller_name
                      IMPORTING is_added            = is_added
                                new_element_id      = new_element_id ).

    ENDIF.

  ENDMETHOD.

  METHOD make_model.

    DATA: element           TYPE element_type,
          element_component TYPE element_comp_type.

    DATA class_id TYPE i.
    DATA method_id TYPE i.

    READ TABLE elements_element_id INTO element WITH TABLE KEY element_id = element_id.
    IF sy-subrc EQ 0.

      element_manager->famix_class->add( EXPORTING name_group = 'WEB_DYNPRO'
                                                   name       = element-wdy_component_name
                                                   modifiers  = 'ABAPWebDynproComponent'
                                         IMPORTING id         = class_id ).

      DATA association TYPE z2mse_extr3_element_manager=>association_type.
      LOOP AT associations INTO association WHERE element_id1 = element_id
                                              AND association->type = z2mse_extr3_association=>parent_package_ass.
        DATA package TYPE REF TO z2mse_extr3_packages.
        package ?= element_manager->get_element( i_element_id = association-element_id2 ).
        element_manager->famix_class->set_parent_package( element_id     = class_id
                                                          parent_package = package->devclass( i_element_id = association-element_id2 ) ).

      ENDLOOP.

      LOOP AT elements_comp_comp_contr_name INTO element_component WHERE wdy_component_name = element-wdy_component_name.
        element_manager->famix_method->add( EXPORTING name = element_component-wdy_controller_name
                                            IMPORTING id = method_id ).

        element_manager->famix_method->set_signature( element_id = method_id
                                       signature = element_component-wdy_controller_name ).
        element_manager->famix_method->set_parent_type(
          EXPORTING
            element_id         = method_id
            parent_element     = 'FAMIX.Class'
            parent_id          = class_id ).

        "! TBD Really required, this appears to be not exact, no namegroup, ...
        element_manager->famix_method->store_id( EXPORTING class  = element-wdy_component_name
                                          method = element_component-wdy_controller_name ).

      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD wdy_component_name.

    DATA element TYPE element_type.

    READ TABLE elements_element_id INTO element WITH TABLE KEY element_id = element_id.
    IF sy-subrc EQ 0.

      wdy_component_name = element-wdy_component_name.

    ENDIF.

  ENDMETHOD.

  METHOD wdy_controller_name.

    DATA element_comp TYPE element_comp_type.

    READ TABLE elements_comp_element_id INTO element_comp WITH KEY element_id = element_id.
    IF sy-subrc EQ 0.

      wdy_component_name = element_comp-wdy_component_name.
      wdy_controller_name = element_comp-wdy_controller_name.

    ENDIF.

  ENDMETHOD.

  METHOD name.

    DATA: wdy_component_name TYPE wdy_component_name.

    wdy_component_name( EXPORTING element_id         = element_id
                        IMPORTING wdy_component_name = wdy_component_name ).

    IF wdy_component_name IS NOT INITIAL.
      element_type = |WebDynproComponent|.
      parent_name = ||.
      name = wdy_component_name.
    ELSE.

      DATA: wdy_controller_name TYPE wdy_controller_name.

      wdy_controller_name( EXPORTING element_id         = element_id
                           IMPORTING wdy_component_name  = wdy_component_name
                                     wdy_controller_name = wdy_controller_name ).

      ASSERT wdy_controller_name IS NOT INITIAL.
      element_type = |WebDynproController|.
      parent_name = wdy_component_name.
      name = wdy_controller_name.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
