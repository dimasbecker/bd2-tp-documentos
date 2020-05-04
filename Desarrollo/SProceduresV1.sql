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

/*c) Creaci�n de un nuevo documento. 
Debe generar no s�lo el documento, sino tambi�n una versi�n inicial asociada a un usuario referente.
El documento reci�n generado no se relaciona con otro y la descripci�n de la versi�n ser� �borrador� hasta ser
aprobado; luego cambiar�.Los par�metros de crear_documento son: @titulo varchar(250), @tipo char(1) y @referente int.*/CREATE PROCEDURE SP_CREAR_DOCUMENTO @TITULO VARCHAR(250), @TIPO CHAR(1), @REFERENTE INTAS BEGIN INSERT INTO DOCUMENTO (TITULO, TIPO, VERSION_ACTUAL) VALUES ( @titulo, @tipo, 'borrador')INSERT INTO VERSION  (ID_DOCUMENTO,VERSION,FECHA_CREACION,BORRADOR,REFERENTE)
SELECT DOCUMENTO.ID, 'borrador', GETDATE(), 1, @REFERENTE FROM DOCUMENTO WHERE TITULO=@TITULO
END--PRUEBA -- EXEC SP_CREAR_DOCUMENTO 'MODELO', 1, 1 --SELECT * FROM DOCUMENTO--SELECT * FROM VERSION/* d) Asociaci�n de documentos. Debe crear una relaci�n entre documentos, del tipo indicado.
De ser �P� (padre), deber reemplazar, de existir, a una previa relaci�n del documento origen de tipo padre. 
Los par�metros de crear_documento son: @documeno_origen int, @documento_destino int, tipo_relaci�n char(1).*/CREATE PROCEDURE SP_ASOCIAR_DOCUMENTO @DOCUMENTO_ORIGEN INT, @DOCUMENTO_DESTINO INT, @TIPO_RELACION CHAR(1)ASIF EXISTS(SELECT ID_DOCUMENTO_DESTINO FROM RELACION WHERE ID_DOCUMENTO_DESTINO = @DOCUMENTO_DESTINO AND TIPO_RELACION = 'P') AND @TIPO_RELACION = 'P'BEGINUPDATE RELACION SET ID_DOCUMENTO_ORIGEN=@DOCUMENTO_ORIGEN WHERE ID_DOCUMENTO_DESTINO=@DOCUMENTO_DESTINO AND TIPO_RELACION= @TIPO_RELACIONENDELSEBEGIN INSERT INTO RELACION (ID_DOCUMENTO_ORIGEN, ID_DOCUMENTO_DESTINO, TIPO_RELACION) VALUES (@DOCUMENTO_ORIGEN, @DOCUMENTO_DESTINO, @TIPO_RELACION)END--PRUEBA -- EXEC SP_ASOCIAR_DOCUMENTO 1,2,P-- SELECT * FROM RELACION