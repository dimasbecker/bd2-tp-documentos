/* b) SP: Cambiar estado de una versi�n de un documento. 
Si bien el estado no est� expl�cito, podemos decir que un documento tiene fases de revisi�n y aprobaci�n,
plasmadas al ser finalizadas en los atributos Revisor y Aprobador de la tabla Versi�n. 

Si un doc no est� aprobado, o revisado, esos atributos est�n en null.

No sepuede cambiar de estado un documento ya aprobado, y en el momento en el que se aprueba, pasa a dejar de ser borrador, 
su fecha de publicaci�n se setea en esemomento, y por �ltimo, el documento pasa a tener como versi�n actual la aprobada,
adem�s de ser la fecha de vencimiento del mismo 6 meses despu�s de laaprobaci�n */

CREATE PROCEDURE SP_REVISION @ID_DOCUMENTO INT, @REVISOR INT --  CREAMOS SP CON DOS VARIABLES
AS 
IF (SELECT APROBADOR FROM VERSION WHERE ID_DOCUMENTO = @ID_DOCUMENTO) IS NOT NULL  -- REIVSAMOS SI EL CAMPO ES NOT NULL
RETURN -- RETORNAMOS LO QUE TENEMOS EN EL CAMPO
ELSE --- SI ES NULL 
BEGIN -- INCIAMOS EL SP
UPDATE VERSION SET REVISOR= @REVISOR WHERE ID_DOCUMENTO=@ID_DOCUMENTO --SETEAMOS UN REVISOR 
END;


CREATE PROCEDURE SP_APROBACION @ID_DOCUMENTO INT, @FECHA_PUBLICACION DATETIME, @VERSION CHAR(8), @APROBADOR INT
AS
IF (SELECT REVISOR FROM VERSION WHERE ID_DOCUMENTO = @ID_DOCUMENTO) IS NULL
RETURN
IF (SELECT APROBADOR FROM VERSION WHERE ID_DOCUMENTO = @ID_DOCUMENTO) IS NOT NULL
RETURN
ELSE
BEGIN 
UPDATE VERSION SET FECHA_PUBLICACION = @FECHA_PUBLICACION, BORRADOR = 0, APROBADOR = @APROBADOR, VERSION = @VERSION WHERE ID=@ID_DOCUMENTO
UPDATE DOCUMENTO SET VERSION_ACTUAL=@VERSION, VENCIMIENTO= DATEADD(MONTH,6,GETDATE()) WHERE ID=@ID_DOCUMENTO
END

--Prueba --EXEC SP_APROBACION @ID_DOCUMENTO=1, @FECHA_PUBLICACION= '2020-03-01', @VERSION='V3', @APROBADOR=1;

