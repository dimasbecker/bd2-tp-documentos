/* b) SP: Cambiar estado de una versi�n de un documento. 
Si bien el estado no est� expl�cito, podemos decir que un documento tiene fases de revisi�n y aprobaci�n,
plasmadas al ser finalizadas en los atributos Revisor y Aprobador de la tabla Versi�n. 
Si un doc no est� aprobado, o revisado, esos atributos est�n en null.
No sepuede cambiar de estado un documento ya aprobado, y en el momento en el que se aprueba, pasa a dejar de ser borrador, 
su fecha de publicaci�n se setea en esemomento, y por �ltimo, el documento pasa a tener como versi�n actual la aprobada,
adem�s de ser la fecha de vencimiento del mismo 6 meses despu�s de laaprobaci�n */

USE ParcialBD2
--
CREATE PROCEDURE SP_REVISION @ID_DOCUMENTO INT, @REVISOR INT --  CREAMOS SP CON DOS VARIABLES
AS 
IF (SELECT APROBADOR FROM VERSION WHERE ID_DOCUMENTO = @ID_DOCUMENTO) IS NOT NULL  -- REIVSAMOS SI EL CAMPO ES NOT NULL
RETURN -- RETORNAMOS LO QUE TENEMOS EN EL CAMPO
ELSE --- SI ES NULL 
BEGIN -- INCIAMOS EL SP
UPDATE VERSION SET REVISOR= @REVISOR WHERE ID_DOCUMENTO=@ID_DOCUMENTO --SETEAMOS UN REVISOR 
END;

-- prueba -- 
EXEC SP_REVISION @ID_DOCUMENTO=4, @REVISOR = 2


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

--Prueba --
EXEC SP_APROBACION @ID_DOCUMENTO=4, @FECHA_PUBLICACION= '2020-03-01', @VERSION='V3', @APROBADOR=1;

/*c) Creaci�n de un nuevo documento. 
Debe generar no s�lo el documento, sino tambi�n una versi�n inicial asociada a un usuario referente.
El documento reci�n generado no se relaciona con otro y la descripci�n de la versi�n ser� �borrador� hasta ser
aprobado; luego cambiar�.Los par�metros de crear_documento son: @titulo varchar(250), @tipo char(1) y @referente int.*/


CREATE PROCEDURE SP_CREAR_DOCUMENTO @TITULO VARCHAR(250), @TIPO CHAR(1), @REFERENTE INT
AS 
BEGIN 
INSERT INTO DOCUMENTO (TITULO, TIPO, VERSION_ACTUAL) VALUES ( @titulo, @tipo, 'borrador')
INSERT INTO VERSION  (ID_DOCUMENTO,VERSION,FECHA_CREACION,BORRADOR,REFERENTE)
SELECT DOCUMENTO.ID, 'borrador', GETDATE(), 1, @REFERENTE FROM DOCUMENTO WHERE TITULO=@TITULO
END



--PRUEBA -- 
EXEC SP_CREAR_DOCUMENTO 'MODELO', 1, 1 

--SELECT * FROM DOCUMENTO
--SELECT * FROM VERSION

/* d) Asociaci�n de documentos. Debe crear una relaci�n entre documentos, del tipo indicado.
De ser �P� (padre), deber reemplazar, de existir, a una previa relaci�n del documento origen de tipo padre. 
Los par�metros de crear_documento son: @documeno_origen int, @documento_destino int, tipo_relaci�n char(1).*/



CREATE PROCEDURE SP_ASOCIAR_DOCUMENTO @DOCUMENTO_ORIGEN INT, @DOCUMENTO_DESTINO INT, @TIPO_RELACION CHAR(1)
AS
IF EXISTS(SELECT ID_DOCUMENTO_DESTINO FROM RELACION WHERE ID_DOCUMENTO_DESTINO = @DOCUMENTO_DESTINO AND TIPO_RELACION = 'P') AND @TIPO_RELACION = 'P'
BEGIN
UPDATE RELACION SET ID_DOCUMENTO_ORIGEN=@DOCUMENTO_ORIGEN WHERE ID_DOCUMENTO_DESTINO=@DOCUMENTO_DESTINO AND TIPO_RELACION= @TIPO_RELACION
END
ELSE
BEGIN 
INSERT INTO RELACION (ID_DOCUMENTO_ORIGEN, ID_DOCUMENTO_DESTINO, TIPO_RELACION) VALUES (@DOCUMENTO_ORIGEN, @DOCUMENTO_DESTINO, @TIPO_RELACION)
END

--PRUEBA --
EXEC SP_ASOCIAR_DOCUMENTO @DOCUMENTO_ORIGEN=3, @DOCUMENTO_DESTINO=4 , @TIPO_RELACION=p
-- SELECT * FROM RELACION

/*g) Eliminar participante. La eliminaci�n debe ser l�gica, bas�ndose en la posibilidad
implementada anteriormente, y los participantes se tienen que reemplazar en orden
inverso a la promoci�n. Si se elimina al referente, debe ser reemplazado por el
revisor. El revisor por el autorizador, y si el autorizador es eliminado, se debe utilizar
el referente. El procedimiento eliminar_participante debe tener un �nico par�metro id
de tipo int.*/

CREATE PROCEDURE SP_ELIMINAR_PARTICIPANTE @ID_ELIMINAR INT
AS
BEGIN
UPDATE PARTICIPANTE	SET ELIMINADO = 0 WHERE ID = @ID_ELIMINAR
IF EXISTS(SELECT REFERENTE FROM VERSION	WHERE REFERENTE = @ID_ELIMINAR) 
UPDATE VERSION	SET REFERENTE = REVISOR	WHERE REFERENTE = @ID_ELIMINAR
IF EXISTS(SELECT REVISOR FROM VERSION WHERE REVISOR = @ID_ELIMINAR)
UPDATE VERSION	SET REVISOR = APROBADOR	WHERE REVISOR = @ID_ELIMINAR
IF EXISTS (SELECT APROBADOR	FROM VERSION WHERE APROBADOR = @ID_ELIMINAR)
UPDATE VERSION SET APROBADOR = REFERENTE WHERE APROBADOR = @ID_ELIMINAR
END

EXEC SP_ELIMINAR_PARTICIPANTE @id_eliminar = 2



--h)Informe Vencimientos
create PROCEDURE SP_INFORME_VENCIMIENTOS
AS
BEGIN
    DECLARE @VENCIMIENTO DATETIME
    DECLARE @ID_DOC INT
    DECLARE @ORDEN INT
    DECLARE @ID_ANTERIOR INT
    DECLARE @VENCIMIENTO_ANTERIOR DATETIME
    SET @ORDEN = 1
	SET IDENTITY_INSERT FUTUROS_VENCIMIENTOS ON


    TRUNCATE TABLE FUTUROS_VENCIMIENTOS

    DECLARE CURSORVENC CURSOR FOR
		SELECT ID, VENCIMIENTO
    FROM DOCUMENTO
    WHERE VENCIMIENTO IS NOT NULL
    ORDER BY VENCIMIENTO ASC
    OPEN CURSORVENC
    FETCH NEXT FROM CURSORVENC INTO @ID_DOC,@VENCIMIENTO
    SET @ID_ANTERIOR = @ID_DOC
    SET @VENCIMIENTO_ANTERIOR = @VENCIMIENTO
    WHILE @@FETCH_STATUS = 0
		BEGIN
        IF((DATEPART(YEAR,@VENCIMIENTO_ANTERIOR) = DATEPART(YEAR,@VENCIMIENTO)) AND (DATEPART(MONTH,@VENCIMIENTO_ANTERIOR) = DATEPART(MONTH,@VENCIMIENTO)))
				BEGIN
            INSERT INTO FUTUROS_VENCIMIENTOS
                (ORDEN,ID_DOCUMENTO,VENCIMIENTO)
            SELECT @ORDEN, @ID_DOC, @VENCIMIENTO
        END
			ELSE
				BEGIN
            SET @ORDEN = @ORDEN + 1
            INSERT INTO FUTUROS_VENCIMIENTOS
                (ORDEN,ID_DOCUMENTO,VENCIMIENTO)
            SELECT @ORDEN, @ID_DOC, @VENCIMIENTO
        END
        SET @ID_ANTERIOR = @ID_DOC
        SET @VENCIMIENTO_ANTERIOR = @VENCIMIENTO
        FETCH NEXT FROM CURSORVENC INTO @ID_DOC,@VENCIMIENTO
    END
    CLOSE CURSORVENC
    DEALLOCATE CURSORVENC
END

exec  SP_INFORME_VENCIMIENTOS
