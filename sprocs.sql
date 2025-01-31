DELIMITER $$



CREATE PROCEDURE AssignAllParentCategories(

    IN in_product_id INT,

    IN in_term_taxonomy_id INT

)

BEGIN

    DECLARE current_ttid INT DEFAULT in_term_taxonomy_id;

    DECLARE parent_ttid INT;



    -- Loop until we reach top-level (parent=0) or no parent

    label_loop: LOOP

        -- Insert current relationship (ignore duplicates)

        INSERT IGNORE INTO wp_term_relationships (object_id, term_taxonomy_id)

        VALUES (in_product_id, current_ttid);

        

        -- Find parent of current

        SELECT parent

          INTO parent_ttid

          FROM wp_term_taxonomy

         WHERE term_taxonomy_id = current_ttid

         LIMIT 1;

        

        -- No more parents?

        IF parent_ttid = 0 OR parent_ttid IS NULL THEN

            LEAVE label_loop;

        END IF;

        

        -- Move up one level

        SET current_ttid = parent_ttid;

    END LOOP label_loop;

END$$



DELIMITER ;





DELIMITER $$



CREATE PROCEDURE PropagateAllCategories()

BEGIN

  DECLARE done INT DEFAULT 0;

  DECLARE var_final_product_id INT;

  DECLARE var_term_taxonomy_id INT;



  -- Cursor to collect all (final_product_id, term_taxonomy_id)

  DECLARE c CURSOR FOR

    SELECT 

      CASE WHEN p.post_type = 'product_variation'

           THEN p.post_parent

           ELSE p.ID

      END AS final_product_id,

      tr.term_taxonomy_id

    FROM wp_posts p

    JOIN wp_term_relationships tr ON p.ID = tr.object_id

    JOIN wp_term_taxonomy tt      ON tr.term_taxonomy_id = tt.term_taxonomy_id

    WHERE p.post_status = 'publish'

      AND p.post_type IN ('product','product_variation')

      AND tt.taxonomy = 'product_cat';



  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;



  OPEN c;

  the_loop: LOOP

    FETCH c INTO var_final_product_id, var_term_taxonomy_id;

    IF done = 1 THEN

      LEAVE the_loop;

    END IF;



    CALL AssignAllParentCategories(var_final_product_id, var_term_taxonomy_id);

  END LOOP the_loop;

  CLOSE c;

END$$



DELIMITER ;

