local Name, Addon = ...
local Locale = Addon.Locale
local lang = "esES"

-- Chat messages
local L = {lang = lang}
setmetatable(L, Locale.MT)
Locale[lang] = L

L["MSG_BID_1"] = "¿Te sirve %s?"
L["MSG_BID_2"] = "Si no necesitas %s, ¿puedes pasármelo?"
L["MSG_BID_3"] = "Me mejora %s, si no lo quieres."
L["MSG_BID_4"] = "Me gustaría tener %s, si no lo quieres para nada."
L["MSG_BID_5"] = "¿Vas a usar %s, o me lo podría quedar yo?"
L["MSG_HER"] = "ella"
L["MSG_HIM"] = "él"
L["MSG_ITEM"] = "objeto"
L["MSG_ROLL_ANSWER_AMBIGUOUS"] = "Ahora mismo estoy repartiendo varios objetos, por favor envíame un enlace del objeto que deseas."
L["MSG_ROLL_ANSWER_BID"] = "Ok, he apuntado tu puja para %s."
L["MSG_ROLL_ANSWER_NO_OTHER"] = "Lo siento, ya se lo he dado a otra persona."
L["MSG_ROLL_ANSWER_NO_SELF"] = "Lo siento, necesito ese objeto."
L["MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Lo siento, no puedo comerciar ese objeto."
L["MSG_ROLL_ANSWER_YES"] = "Para ti, comercia conmigo."
L["MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Puedes quedártelo, comercia a <%s>."
L["MSG_ROLL_START"] = "Ofrezco %s -> susúrrame o haz /roll %d!"
L["MSG_ROLL_START_MASTERLOOT"] = "Ofrezco %s de <%s> -> susúrrame o haz /roll %d!"
L["MSG_ROLL_WINNER"] = "<%s> ha ganado %s -> ¡Comercia conmigo!"
L["MSG_ROLL_WINNER_MASTERLOOT"] = "<%s> ha ganado %s de <%s> -> ¡Comercia con %s!"
L["MSG_ROLL_WINNER_WHISPER"] = "¡Has ganado %s! Por favor comercia conmigo."
L["MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "¡Has ganado %s de %s! Por favor comercia con %s."

-- Addon
local L = LibStub("AceLocale-3.0"):NewLocale(Name, lang, lang == Locale.FALLBACK)
if not L then return end

L["ACTION"] = "Acción"
L["ACTIONS"] = "Acciones"
L["ADVERTISE"] = "Anunciar en el chat"
L["ANSWER"] = "Respuesta"
L["ASK"] = "Solicitar"
L["AWARD"] = "Entregar"
L["AWARD_LOOT"] = "Entregar loot"
L["AWARD_RANDOMLY"] = "Entregar al azar"
L["BID"] = "Solicitar"
L["COMMUNITY_GROUP"] = "Grupo de Comunidad"
L["COMMUNITY_MEMBER"] = "Miembro de Comunidad"
L["DISABLED"] = "Desactivado"
L["DOWN"] = "abajo"
L["ENABLED"] = "Activado"
L["EQUIPPED"] = "Equipado"
L["GET_FROM"] = "Obtener de"
L["GIVE_AWAY"] = "Entregar"
L["GIVE_TO"] = "Entregar a"
L["GUILD_MASTER"] = "Maestro de Clan"
L["GUILD_OFFICER"] = "Oficial de Clan"
L["HIDE"] = "Ocultar"
L["HIDE_ALL"] = "Ocultar todo"
L["ITEM"] = "objeto"
L["ITEM_LEVEL"] = "Nivel de objeto"
L["KEEP"] = "Quedármelo"
L["LEFT"] = "izquierda"
L["MASTERLOOTER"] = "Maestro despojador"
L["MESSAGE"] = "Mensaje"
L["ML"] = "MD"
L["OPEN_ROLLS"] = "Abrir ventana de tiradas"
L["OWNER"] = "Dueño"
L["PLAYER"] = "Jugador"
L["PRIVATE"] = "Privado"
L["PUBLIC"] = "Público"
L["RAID_ASSISTANT"] = "Asistente de raid"
L["RAID_LEADER"] = "Líder de raid"
L["RESTART"] = "Reinicio"
L["RIGHT"] = "correcto"
L["ROLL"] = "Tirar dados"
L["ROLLS"] = "Tiradas de dado"
L["SECONDS"] = "%ds"
L["SET_ANCHOR"] = "Selección de anclaje: Crecimiento %s y %s"
L["SHOW"] = "Mostrar"
L["SHOW_HIDE"] = "Mostrar/Ocultar"
L["TRADE"] = "Comercia"
L["UP"] = "Arriba"
L["VERSION_NOTICE"] = "Hay una versión nueva de este addon disponible. Por favor, actualízalo para mantenerte compatible con todo el mundo y no perderte nada de loot!"
L["VOTE"] = "Votar"
L["VOTE_WITHDRAW"] = "Retirarse"
L["VOTES"] = "Votos"
L["WINNER"] = "Ganador"
L["WON"] = "Ganado"
L["YOUR_BID"] = "Tu puja"

-- Commands
L["HELP"] = [=[Realiza tiradas y pujas por objetos (/PersoLootRoll o /plr).
Uso:
/plr: Abre la ventana de opciones
/plr roll [item]* (<timeout> <owner>): Empezar una tirada por uno o más objeto(s)
/plr bid <owner> ([item]): Pujar por un objeto de otro jugador
/plr options: Abrir la ventana de opciones
/plr config: Cambiar la configuración a través de la línea de comandos
/plr help: Mostrar este mensaje de ayuda
Leyenda: [..] = enlace del objeto, * = una o más veces, (..) = opcional]=]
L["USAGE_BID"] = "Uso: /plr bid <dueño> ([ítem])"
L["USAGE_ROLL"] = "Uso: /plr roll [ítem]* (<plazo> <dueño>)"

-- Errors
L["ERROR_CMD_UNKNOWN"] = "Comando '%s' desconocido "
L["ERROR_ITEM_NOT_TRADABLE"] = "No puedes comerciar con ese objeto."
L["ERROR_NOT_IN_GROUP"] = "No estás en un grupo o banda."
L["ERROR_OPT_MASTERLOOT_EXPORT_FAILED"] = "¡La exportación de la configuración de maestro despojador a <%s> falló!"
L["ERROR_PLAYER_NOT_FOUND"] = "No se encuentra al jugador %s."
L["ERROR_ROLL_BID_IMPOSSIBLE_OTHER"] = "%s ha enviado una puja por %s pero no tiene permiso para hacerlo ahora."
L["ERROR_ROLL_BID_IMPOSSIBLE_SELF"] = "No puedes solicitar ese objeto ahora."
L["ERROR_ROLL_BID_UNKNOWN_OTHER"] = "%s ha enviado una puja incorrecta por %s."
L["ERROR_ROLL_BID_UNKNOWN_SELF"] = "Esa no es una puja correcta."
L["ERROR_ROLL_STATUS_NOT_0"] = "La tirada ya ha empezado o terminado."
L["ERROR_ROLL_STATUS_NOT_1"] = "La tirada no está en marcha."
L["ERROR_ROLL_UNKNOWN"] = "Esa tirada no existe."
L["ERROR_ROLL_VOTE_IMPOSSIBLE_OTHER"] = "%s ha enviado un voto por %s pero no puede hacerlo ahora mismo."
L["ERROR_ROLL_VOTE_IMPOSSIBLE_SELF"] = "No puedes votar por ese objeto ahora mismo."

-- GUI
L["DIALOG_MASTERLOOT_ASK"] = "<%s> quiere convertirse en tu maestro despojador."
L["DIALOG_OPT_MASTERLOOT_LOAD"] = "Esto reemplazará tu configuración actual de maestro despojador con la configurada en la información de la hermandad/comunidad, ¿estás seguro de que deseas continuar?"
L["DIALOG_OPT_MASTERLOOT_SAVE"] = "Esto reemplazará la configuración de maestro despojador almacenada en la información de la hermandad/comunidad con tu configuración actual, ¿estás seguro de que deseas continuar?"
L["DIALOG_ROLL_CANCEL"] = "¿Quieres cancelar esta tirada?"
L["DIALOG_ROLL_RESTART"] = "¿Quieres reiniciar esta tirada?"
L["FILTER"] = "Filtrar"
L["FILTER_ALL"] = "Para todos los jugadores."
L["FILTER_ALL_DESC"] = "Incluye tiradas de todos los jugadores, no sólo las tuyas o aquellas de objetos que te pueden interesar."
L["FILTER_AWARDED"] = "Entregado"
L["FILTER_AWARDED_DESC"] = "Incluir objetos que han sido ganados por otros,"
L["FILTER_DONE"] = "Hecho"
L["FILTER_DONE_DESC"] = "Incluir tiradas que han terminado."
L["FILTER_HIDDEN"] = "Oculto"
L["FILTER_HIDDEN_DESC"] = "Incluir tiradas canceladas, pendientes, realizadas y ocultas."
L["FILTER_TRADED"] = "Comerciado"
L["FILTER_TRADED_DESC"] = "Incluir tiradas cuyos objetos han sido comerciados."
L["MENU_MASTERLOOT_SEARCH"] = "Buscar un maestro despojador en el grupo"
L["MENU_MASTERLOOT_START"] = "Convertirte en maestro despojador"
L["TIP_ADDON_MISSING"] = "Falta addon:"
L["TIP_ADDON_VERSIONS"] = "Versiones del addon:"
L["TIP_CHAT_TO_TRADE"] = "Por favor, antes de comerciar pregunta al dueño"
L["TIP_ENABLE_WHISPER_ASK"] = "Consejo: clic-derecho para habilitar la petición automática de loot"
L["TIP_MASTERLOOT"] = "Maestro despojador activo"
L["TIP_MASTERLOOT_INFO"] = [=[|cffffff78Maestro despojador:|r %s
|cffffff78Tiempo de reparto:|r %ds (+ %ds per item)
|cffffff78Consejo de loot:|r %s
|cffffff78Pujas:|r %s
|cffffff78Votos:|r %s]=]
L["TIP_MASTERLOOT_START"] = "Convertirse en maestro despojador o buscar uno"
L["TIP_MASTERLOOT_STOP"] = "Quitar el maestro despojador"
L["TIP_MASTERLOOTING"] = "Grupo con maestro despojador (%d): "
L["TIP_MINIMAP_ICON"] = [=[|cffffff78Clic-izquierdo:|r Fija la ventana de repartos
|cffffff78Clic-derecho:|r Muestra Opciones]=]
L["TIP_PLH_USERS"] = "Usuarios de PLH:"
L["TIP_VOTES"] = "Votos de:"

-- Options - Home
L["OPT_ACTIONS_WINDOW"] = "Mostrar ventana de acciones"
L["OPT_ACTIONS_WINDOW_DESC"] = "Muestra la ventana de acciones cuando hay acciones pendientes, por ej. cuando ganas un objeto y tienes que comerciar con alguien para conseguirlo."
L["OPT_ACTIONS_WINDOW_MOVE"] = "Mover"
L["OPT_ACTIONS_WINDOW_MOVE_DESC"] = "Mueve la ventana de acciones."
L["OPT_ACTIVE_GROUPS"] = "Activar por tipo de grupo"
L["OPT_ACTIVE_GROUPS_DESC"] = [=[Activar sólo cuando estás en uno de estos tipos de grupo.

|cffffff78Grupo de heramandad:|r Los miembros de una hermandad son el %d%% o más del grupo.
|cffffff78Grupo de comunidad:|r Los miembros de una de tus comunidades de WoW son el %d%% o más del grupo]=]
L["OPT_AUTHOR"] = "|cffffd100Autor:|r Shrugal (EU-Mal'Ganis)"
L["OPT_AWARD_SELF"] = "Elegir manualmente el ganador de tus objetos"
L["OPT_AWARD_SELF_DESC"] = "Escoger manualmente quién debe recibir tus objetos, en lugar de dejar que el addon elija a alguien al azar. Esto está siempre activado cuando eres el maestro despojador."
L["OPT_BID_PUBLIC"] = "Publicar las pujas"
L["OPT_BID_PUBLIC_DESC"] = "Las pujas de tus tiradas son públicas, por lo que todo el que tenga el addon puede verlas."
L["OPT_CHILL_MODE"] = "Chill mode" -- Translation missing
L["OPT_CHILL_MODE_DESC"] = [=[The intent of chill mode is to take the pressure out of sharing the loot, even if that means that things will take a bit longer. If you enable it the following things will change:

|cffffff781.|r Rolls from you won't start until you actually decided to share them, so you have as much time as you want to choose, and other addon users won't see your items util you did.
|cffffff782.|r Rolls from you have double the normal run-time, or no run-time at all if you enabled to choose winners of your own items yourself (see next option).
|cffffff783.|r Rolls from non-addon users in your group also stay open until you decided if you want them or not.

|cffff0000IMPORTANT:|r Rolls from other addon users without chill mode active will still have a normal timeout. Make sure that everyone in your group enables this option if you want a chill run.]=] -- Translation missing
L["OPT_DONT_SHARE"] = "No compartir objetos"
L["OPT_DONT_SHARE_DESC"] = "No tirar por objetos de otros jugadores y no compartir mis objetos. El addon rechazará las peticiones de mis objetos (si está activado), y podrás seguir  siendo maestro despojador y miembro del 'loot council'."
L["OPT_ENABLE"] = "Activar"
L["OPT_ENABLE_DESC"] = "Activa o desactiva el addon"
L["OPT_ILVL_THRESHOLD"] = "Límite de nivel de objeto"
L["OPT_ILVL_THRESHOLD_DESC"] = "Los objetos cuyo nivel de objeto esté por debajo del tuyo en más de esta cantidad serán ignorados."
L["OPT_ILVL_THRESHOLD_RINGS"] = "Duplicar el límite en los anillos"
L["OPT_ILVL_THRESHOLD_RINGS_DESC"] = "Los anillos tienen que tener el doble del límite porque su valor puede variar mucho al no tener la estadística principal."
L["OPT_ILVL_THRESHOLD_TRINKETS"] = "Duplicar el límite en los abalorios"
L["OPT_ILVL_THRESHOLD_TRINKETS_DESC"] = "Los abalorios tienen que tener el doble del límite de nivel de objeto porque sus efectos pueden en gran medida modificar su valor."
L["OPT_INFO"] = "Información"
L["OPT_INFO_DESC"] = "Algo de información sobre este addon."
L["OPT_ITEM_FILTER"] = "Filtro de Objetos"
L["OPT_ITEM_FILTER_DESC"] = "Cambiar por qué objetos se te solicita tirar dados."
L["OPT_MINIMAP_ICON"] = "Mostrar el icono del minimapa"
L["OPT_MINIMAP_ICON_DESC"] = "Muestra u oculta el icono del minimapa."
L["OPT_ONLY_MASTERLOOT"] = "Sólo maestro despojador"
L["OPT_ONLY_MASTERLOOT_DESC"] = "El addon sólo se activa cuando se use maestro despojador (p.e. con tu hermandad)"
L["OPT_PAWN"] = "Comprobar el \"Pawn\""
L["OPT_PAWN_DESC"] = "Optar solamente por objetos que sean una mejora según el addon \"Pawn\"."
L["OPT_ROLL_FRAMES"] = "Mostrar cuadros de loot"
L["OPT_ROLL_FRAMES_DESC"] = "Muestra cuadros de loot cuando alguien recibe algo en lo que tú puedas estar interesado, de manera que puedas optar a ello."
L["OPT_ROLLS_WINDOW"] = "Mostrar ventana de repartos"
L["OPT_ROLLS_WINDOW_DESC"] = "Siempre muestra la ventana de repartos (con todas las tiradas de dados en ella) cuando alguien recibe algo en lo que tú puedas estar interesado. Esta opción siempre está activa si eres maestro despojador."
L["OPT_SPECS"] = "Especializaciones"
L["OPT_SPECS_DESC"] = "Sólo sugiere loot a estas especializaciones de clase."
L["OPT_TRANSLATION"] = "|cffffd100Traducción:|r Jolugon (EU-Minahonda)"
L["OPT_TRANSMOG"] = "Comprobar apariencias para transfiguración"
L["OPT_TRANSMOG_DESC"] = "Optar a los ítems para los que aún no tienes la apariencia correspondiente."
L["OPT_UI"] = "Interfaz de usuario"
L["OPT_UI_DESC"] = "Personaliza la apariencia y comportamiento de %s a tu gusto."
L["OPT_VERSION"] = "|cffffd100Versión:|r %s"

-- Options - Masterloot
L["OPT_MASTERLOOT"] = "Maestro despojador"
L["OPT_MASTERLOOT_APPROVAL"] = "Aprobado"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT"] = "Aceptar automáticamente el maestro despojador"
L["OPT_MASTERLOOT_APPROVAL_ACCEPT_DESC"] = "Aceptar automáticamente peticiones de maestro despojador de estos jugadores."
L["OPT_MASTERLOOT_APPROVAL_ALLOW"] = "Permitir convertirse en maestro despojador"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL"] = "Permitir a cuaquiera"
L["OPT_MASTERLOOT_APPROVAL_ALLOW_ALL_DESC"] = "|cffff0000WARNING:|r ¡Esto permitirá a cualquiera convertirse en tu maestro despojador y puede aprovecharse para llevarse tus objetos! Activarlo sólo si sabes lo que estás haciendo."
L["OPT_MASTERLOOT_APPROVAL_ALLOW_DESC"] = [=[Elige quién puede solicitar convertirse en tu maestro despojador. Aun así recibirás un mensaje para confirmarlo, por lo que puedes denegar la solicitud de maestro despojador cuando ocurra.

|cffffff78Grupo de Hermandad:|r Alguien de la hermandad cuyos miembros son %d%% o más del grupo.]=]
L["OPT_MASTERLOOT_APPROVAL_DESC"] = "Aquí puedes definir quien se convertirá en tu maestro despojador."
L["OPT_MASTERLOOT_APPROVAL_WHITELIST"] = "Lista blanca del maestro despojador"
L["OPT_MASTERLOOT_APPROVAL_WHITELIST_DESC"] = "También puede nombrar a jugadores específicos que podrán volverse tu maestro despojador. Separa sus nombres con espacios o comas."
L["OPT_MASTERLOOT_CLUB"] = "Hermandad/Comunidad"
L["OPT_MASTERLOOT_CLUB_DESC"] = "Selecciona la Hermandad/Comunidad de la que importar/exportar la configuración."
L["OPT_MASTERLOOT_COUNCIL"] = "Consejo"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK"] = "Rango del Consejo de la hermandad/comunidad"
L["OPT_MASTERLOOT_COUNCIL_CLUB_RANK_DESC"] = "Añadir los miembros de este rango de la hermandad/comunidad al consejo, además de las opciones anteriores"
L["OPT_MASTERLOOT_COUNCIL_DESC"] = "Los jugadores que estén en tu consejo de loot pueden votar quién debe recibir el loot."
L["OPT_MASTERLOOT_COUNCIL_ROLES"] = "Roles del consejo"
L["OPT_MASTERLOOT_COUNCIL_ROLES_DESC"] = "Qué jugadores deben convertirse automáticamente en parte de tu consejo de loot."
L["OPT_MASTERLOOT_COUNCIL_WHITELIST"] = "Lista blanca del consejo de loot"
L["OPT_MASTERLOOT_COUNCIL_WHITELIST_DESC"] = "También puedes nombrar a jugadores específicos para que estén en tu consejo de loot. Si hay más de uno, sepáralos con espacios o comas."
L["OPT_MASTERLOOT_DESC"] = "Cuando tú (u otra persona) se convierte en maestro despojador, todo el loot se distribuirá a esa persona. Recibirás una notificación sobre qué piezas te llevas o quién se lleva las que te toquen a ti, de forma que puedas comerciarlas con la persona adecuada."
L["OPT_MASTERLOOT_EXPORT_DONE"] = "La configuración de maestro despojador se exportó con éxito a <%s>."
L["OPT_MASTERLOOT_EXPORT_GUILD_ONLY"] = "Por favor, reemplaza la información actual de la comunidad con este texto, porque el reemplazo automático sólo es posible para hermandades."
L["OPT_MASTERLOOT_EXPORT_NO_PRIV"] = "Por favor, pide a un líder que reemplace la información de la hermandad con este texto, porque tú no tienes permisos para poder hacerlo."
L["OPT_MASTERLOOT_EXPORT_WINDOW"] = "Exportar la configuración de maestro despojador"
L["OPT_MASTERLOOT_LOAD"] = "Cargar"
L["OPT_MASTERLOOT_LOAD_DESC"] = "Cargar la configuración de maestro despojador desde la descripción de tu hermandad/comunidad."
L["OPT_MASTERLOOT_RULES"] = "Reglas"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD"] = "Dar loot automáticamente"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_DESC"] = "Dejar que el addon decida quién tiene que recibir el loot, basándose en factores como los votos del consejo de loot, pujas e ilvl equipado."
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT"] = "Tiempo de espera (base) para el reparto automático del loot"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_DESC"] = "Tiempo de espera base a esperar antes activar el reparto automático del loot, de manera que tengas tiempo de recolectar votos o incluso decidir tú mismo quién lo recibe."
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM"] = "Tiempo de espera para el reparto automático (por ítem)"
L["OPT_MASTERLOOT_RULES_AUTO_AWARD_TIMEOUT_PER_ITEM_DESC"] = "Será añadido al tiempo base de espera para reparto automático para cada ítem que caiga."
L["OPT_MASTERLOOT_RULES_BID_PUBLIC"] = "Pujas públicas"
L["OPT_MASTERLOOT_RULES_BID_PUBLIC_DESC"] = "Puedes hacer pujas públicas, de manera que todo el mundo pueda ver quién puja por qué."
L["OPT_MASTERLOOT_RULES_DESC"] = "Estas reglas aplican a todo el mundo cuando tú eres maestro despojador"
L["OPT_MASTERLOOT_RULES_DISENCHANTER"] = "Desencantador"
L["OPT_MASTERLOOT_RULES_DISENCHANTER_DESC"] = "Dar el loot que nadie quiera a estos jugadores para desencantar."
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS"] = "Respuestas tipo 'Codicia' personalizadas"
L["OPT_MASTERLOOT_RULES_GREED_ANSWERS_DESC"] = [=[Especifica un máximo de 9 respuestas personalizadas cuando se opte por 'Codicia', con prioridad decreciente. También puedes insertar '%s' a la misma para bajar su prioridad por debajo de las respuestas previas. Para introducir entradas múltiples, sepáralas por comas.

Se puede acceder a ellas haciendo clic con el botón derecho en el botón de 'Codicia' cuando se reparte el loot.]=]
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS"] = "Respuestas tipo 'Necesidad' personalizadas"
L["OPT_MASTERLOOT_RULES_NEED_ANSWERS_DESC"] = [=[Especifica un máximo de 9 respuestas personalizadas cuando se opte por 'Necesidad', con prioridad decreciente. También puedes insertar '%s' a la misma para bajar su prioridad por debajo de las respuestas previas. Para introducir entradas múltiples, sepáralas por comas.

Se puede acceder a ellas haciendo clic con el botón derecho en el botón de 'Necesidad' cuando se reparte el loot.]=]
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE"] = "Tiempo (base) para optar a algo"
L["OPT_MASTERLOOT_RULES_TIMEOUT_BASE_DESC"] = "Tiempo base durante el que se puede optar a ítems, independientemente de cuántos hayan caído."
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM"] = "Tiempo para optar (por ítem)"
L["OPT_MASTERLOOT_RULES_TIMEOUT_PER_ITEM_DESC"] = "Será añadido al tiempo de espera base por cada ítem que caiga."
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC"] = "Votación pública"
L["OPT_MASTERLOOT_RULES_VOTE_PUBLIC_DESC"] = "Puedes hacer que las votaciones del consejo de loot sean públicas, de manera que todo el mundo pueda ver cuántos votos recibió cada uno."
L["OPT_MASTERLOOT_SAVE"] = "Guardar"
L["OPT_MASTERLOOT_SAVE_DESC"] = "Guarda la configuración actual de maestro despojador en la descripción de tu hermandad/comunidad."

-- Options - Messages
L["OPT_CUSTOM_MESSAGES"] = "Mensajes personalizados"
L["OPT_CUSTOM_MESSAGES_DEFAULT"] = "Idioma por defecto (%s)"
L["OPT_CUSTOM_MESSAGES_DEFAULT_DESC"] = "Estos mensajes se utilizarán cuando el receptor hable %s u otro idioma distinto del de tu reino (%s)"
L["OPT_CUSTOM_MESSAGES_DESC"] = "Puedes re ordenar los textos de sustitución (|cffffff78%s|r, |cffffff78%d|r) añadiendo su posición y un símbolo de dolar $ en el medio, por ej. |cffffff78%2$s|r en lugar de |cffffff78%s|r para el segundo texto de sustitución. Mira en la ventana emergente para tener más detalles."
L["OPT_CUSTOM_MESSAGES_LOCALIZED"] = "Idioma del reino (%s)"
L["OPT_CUSTOM_MESSAGES_LOCALIZED_DESC"] = "Estos mensajes se usarán cuando el receptor hable el idioma de tu reino (%s)."
L["OPT_ECHO"] = "Información de chat"
L["OPT_ECHO_DEBUG"] = "Depurar"
L["OPT_ECHO_DESC"] = [=[¿Cuánta información quieres ver del addon en el chat?

|cffffff78Ninguna:|r Sin información en el chat.
|cffffff78Error:|r Sólo mensajes de error.
|cffffff78Info:|r Errores e información útil que probablemente quieras conocer.
|cffffff78Verbose:|r Información sobre casi todo lo que hace el addon.
|cffffff78Depurar:|r Como verbose, pero con información de depuración adicional.]=]
L["OPT_ECHO_ERROR"] = "Error"
L["OPT_ECHO_INFO"] = "Información"
L["OPT_ECHO_NONE"] = "Nada"
L["OPT_ECHO_VERBOSE"] = "Detallar"
L["OPT_GROUPCHAT"] = "Chat de grupo"
L["OPT_GROUPCHAT_ANNOUNCE"] = "Anunciar tiradas y ganadores"
L["OPT_GROUPCHAT_ANNOUNCE_DESC"] = "Anunciar tus tiradas y los ganadores de tus tiradas en el chat de grupo."
L["OPT_GROUPCHAT_DESC"] = "Selecciona si el addon mostrará o no información por el chat de grupo."
L["OPT_GROUPCHAT_GROUP_TYPE"] = "Anunciar por tipo de grupo"
L["OPT_GROUPCHAT_GROUP_TYPE_DESC"] = [=[Escribe en el chat de grupo sólo si estás en uno de estos tipos de grupo.

|cffffff78Grupo de Hermandad:|r Los miembros de una hermandad son %d%% o más del grupo.
|cffffff78Grupo de Comunidad:|r Los miembros de una de tus Comunidades del WoW son %d%%  o más del grupo.]=]
L["OPT_GROUPCHAT_ROLL"] = "Tirar por los objetos en el chat"
L["OPT_GROUPCHAT_ROLL_DESC"] = "Tirar dados para objetos que quieres (/roll) si otros jugadores ponen enlaces de esos objetos en el chat de grupo."
L["OPT_MESSAGES"] = "Mensajes"
L["OPT_MSG_BID"] = "Pedir loot: Variante %d"
L["OPT_MSG_BID_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS"] = "Respuesta: Mándame el enlace del objeto"
L["OPT_MSG_ROLL_ANSWER_AMBIGUOUS_DESC"] = "-"
L["OPT_MSG_ROLL_ANSWER_BID"] = "Respuesta: Puja registrada"
L["OPT_MSG_ROLL_ANSWER_BID_DESC"] = "1: Item link"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER"] = "Respuesta: Se lo di a otra persona"
L["OPT_MSG_ROLL_ANSWER_NO_OTHER_DESC"] = "-"
L["OPT_MSG_ROLL_ANSWER_NO_SELF"] = "Respuesta: Lo necesito para mí"
L["OPT_MSG_ROLL_ANSWER_NO_SELF_DESC"] = "-"
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE"] = "Respuesta: No se puede comerciar"
L["OPT_MSG_ROLL_ANSWER_NOT_TRADABLE_DESC"] = "-"
L["OPT_MSG_ROLL_ANSWER_YES"] = "Respuesta: Para ti"
L["OPT_MSG_ROLL_ANSWER_YES_DESC"] = "-"
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT"] = "Respuesta: Para ti (como maestro despojador)"
L["OPT_MSG_ROLL_ANSWER_YES_MASTERLOOT_DESC"] = "1: El dueño del objeto"
L["OPT_MSG_ROLL_START"] = "Anunciando un nuevo reparto"
L["OPT_MSG_ROLL_START_DESC"] = [=[1: Enlace del ítem
2: Número de la tirada de dados]=]
L["OPT_MSG_ROLL_START_MASTERLOOT"] = "Anunciando un nuevo reparto (como maestro despojador)"
L["OPT_MSG_ROLL_START_MASTERLOOT_DESC"] = [=[1: Enlace del objeto
2: Dueño del objeto
3: Número de la tirada de dados]=]
L["OPT_MSG_ROLL_WINNER"] = "Anunciando el ganador de un reparto"
L["OPT_MSG_ROLL_WINNER_DESC"] = [=[1: Ganador
2: Enlace del objeto]=]
L["OPT_MSG_ROLL_WINNER_MASTERLOOT"] = "Anunciando el ganador de un reparto (como maestro despojador)"
L["OPT_MSG_ROLL_WINNER_MASTERLOOT_DESC"] = [=[1: Ganador
2: Enlace del objeto
3: Dueño del objeto
4: Él/ella]=]
L["OPT_MSG_ROLL_WINNER_WHISPER"] = "Susurrando el ganador del reparto"
L["OPT_MSG_ROLL_WINNER_WHISPER_DESC"] = "1: Enlace del objeto"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT"] = "Susurrando el ganador del reparto (como maestro despojador)"
L["OPT_MSG_ROLL_WINNER_WHISPER_MASTERLOOT_DESC"] = [=[1: Enlace del objeto
2: Dueño del objeto
3: Él/ella]=]
L["OPT_SHOULD_CHAT"] = "Habilitar/Deshabilitar"
L["OPT_SHOULD_CHAT_DESC"] = "Define cuándo el addon escribirá en el chat de grupo/raid y susurrará a otros jugadores."
L["OPT_WHISPER"] = "Chat de susurros"
L["OPT_WHISPER_ANSWER"] = "Peticiones de respuesta"
L["OPT_WHISPER_ANSWER_DESC"] = "Dejar que el addon conteste a susurros provenientes de miembros del grupo acerca de objetos que has looteado."
L["OPT_WHISPER_ASK"] = "Preguntar por loot"
L["OPT_WHISPER_ASK_DESC"] = "Susurrar a otros si tienen loot que tú quieres."
L["OPT_WHISPER_DESC"] = "Selecciona si el addon va a susurrar a otros jugadores y/o responder mensajes entrantes."
L["OPT_WHISPER_GROUP"] = "Susurrar por tipo de grupo"
L["OPT_WHISPER_GROUP_DESC"] = "Susurra a otros si tienen loot que tú quieres, dependiendo del tipo de grupo en el que te encuentres."
L["OPT_WHISPER_GROUP_TYPE"] = "Preguntar según tipo de grupo"
L["OPT_WHISPER_GROUP_TYPE_DESC"] = [=[Preguntar por loot sólo si estás en uno de estos tipos de grupo..

|cffffff78Grupo de hermandad:|r Los miembros de una hermandad son el %d%% o más del grupo.
|cffffff78Grupo de comunidad:|r Los miembros de una de tus comunidades de WoW son el %d%% o más del grupo.]=]
L["OPT_WHISPER_SUPPRESS"] = "Suprimir peticiones"
L["OPT_WHISPER_SUPPRESS_DESC"] = "Eliminar susurros entrantes de jugadores elegibles cuando repartas tu loot."
L["OPT_WHISPER_TARGET"] = "Pedir según objetivo"
L["OPT_WHISPER_TARGET_DESC"] = "Pedir loot dependiendo de si el objetivo está en tu hermandad, en una de tus comunidades de WoW o en tu lista de amigos."
L["OPT_WHISPER_ASK_VARIANTS"] = "Enable ask variants" -- Translation missing
L["OPT_WHISPER_ASK_VARIANTS_DESC"] = "Use different lines (see below) when asking for loot, to make it less repetitive." -- Translation missing

-- Roll
L["BID_CHAT"] = "Solicitando a %s el objeto %s -> %s."
L["BID_MAX_WHISPERS"] = "No voy a solicitar a %s el objeto %s, porque %d de los jugadores en tu grupo ya lo han solicitado -> %s."
L["BID_NO_CHAT"] = "No voy a solicitar a %s el objeto %s, porque está desactivado para el grupo u objetivo -> %s."
L["BID_PASS"] = "Pasando de %s de %s."
L["BID_START"] = "Pujando con %q por %s de %s."
L["MASTERLOOTER_OTHER"] = "Ahora %s es tu maestro despojador."
L["MASTERLOOTER_SELF"] = "Ahora eres el maestro despojador."
L["ROLL_AWARDED"] = "Adjudicado"
L["ROLL_AWARDING"] = "Adjudicando"
L["ROLL_CANCEL"] = "Cancelando reparto del objeto %s de %s."
L["ROLL_END"] = "Finalizando reparto del objeto %s de %s."
L["ROLL_IGNORING_BID"] = "Ignorando la puja de %s para %s, porje has chateado antes -> Puja: %s o %s."
L["ROLL_LIST_EMPTY"] = "Las pujas activas se mostrarán aquí"
L["ROLL_START"] = "Comenzando puja para %s de %s."
L["ROLL_STATUS_0"] = "Pendiente"
L["ROLL_STATUS_1"] = "En marcha"
L["ROLL_STATUS_-1"] = "Cancelado"
L["ROLL_STATUS_2"] = "Hecho"
L["ROLL_TRADED"] = "Comerciado"
L["ROLL_WHISPER_SUPPRESSED"] = "Puja de %s para %s -> %s / %s."
L["ROLL_WINNER_MASTERLOOT"] = "%s ha ganado %s de %s."
L["ROLL_WINNER_OTHER"] = "%s ha ganado tu objeto %s -> %s"
L["ROLL_WINNER_OWN"] = "Has ganado tu propio objeto %s."
L["ROLL_WINNER_SELF"] = "Has ganado %s de %s -> %s."
L["TRADE_CANCEL"] = "Cancelando comercio con %s."
L["TRADE_START"] = "Empezando comercio con %s."

-- Globals
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_ADDON = "El dueño de este objeto no usa el addon PersoLootRoll."
LOOT_ROLL_INELIGIBLE_REASONPLR_NO_DISENCHANT = "El addon PersoLootRoll no incluye opción de desencantar."

-- Other
L["ID"] = ID
L["ITEMS"] = ITEMS
L["LEVEL"] = LEVEL
L["STATUS"] = STATUS
L["TARGET"] = TARGET
L["ROLL_BID_1"] = NEED
L["ROLL_BID_2"] = GREED
L["ROLL_BID_3"] = ROLL_DISENCHANT
L["ROLL_BID_4"] = PASS
