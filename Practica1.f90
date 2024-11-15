module modulo_inventario
    implicit none

    type :: equipo
        character(len=20) :: nombre
        integer :: cantidad
        real :: precio_unitario
        character(len=20) :: ubicacion
    end type equipo

end module modulo_inventario

program practica1
    use modulo_inventario
    implicit none

    integer :: opcion, num_equipo
    type(equipo), allocatable :: inventario(:)

    do
        print *, ''
        print *, '-------------------------------------------------'
        print *, 'Practica 1 - Lenguajes Formales y de Programacion'
        print *, '-------------------------------------------------'
        print *, '# Sistema de Inventario: '
        print *, ''
        print *, '1. Cargar inventario Inicial'
        print *, '2. Cargar Instrucciones de Movimientos'
        print *, '3. mostrar Informe de Inventario'
        print *, '4. Eliminar Equipo'
        print *, '5. Salir'
        print *, ''
        print *, 'Ingrese una opcion: '
        read *, opcion

        select case (opcion)
            case (1)
                print *, ''
                print *, 'Cargando inventario...'
                call cargar_inventario('inventario.inv', inventario, num_equipo)
            case (2)
                print *, ''
                print *, 'Mostrando instrucciones de movimientos...'
                call agregar_stock('instrucciones.mov', inventario, num_equipo)
            case (3)
                print *, ''
                print *, 'Mostrando informe de inventario...'
                call mostrar_inventario(inventario, num_equipo)
                call mostrar_inventario_txt('inventario.txt', inventario, num_equipo)
            case (4)
                print *, ''
                print *, 'Eliminando equipo...'
                call eliminar_equipos('instrucciones.mov', inventario, num_equipo)
            case (5)
                print *, ''
                print *, 'Saliendo...'
                exit
            case default
                print *, 'Opcion no valida'
        end select
    end do

contains

    subroutine cargar_inventario(nombre_archivo, inventario, num_equipo)
        implicit none
        character(len=*), intent(in) :: nombre_archivo
        type(equipo), allocatable, intent(out) :: inventario(:)
        integer, intent(out) :: num_equipo
        character(len=100) :: linea
        integer :: i, ios
        character(len=20) :: nombre, ubicacion
        integer :: cantidad
        real :: precio_unitario

        open(unit=10, file=nombre_archivo, status='old', action='read', iostat=ios)
        if (ios /= 0) then
            print *, 'Error al abrir el archivo', trim(nombre_archivo)
            return
        end if

        num_equipo = 0

        do
            read(10, '(A)', iostat=ios) linea
            if (ios /= 0) exit
            num_equipo = num_equipo + 1
        end do
        rewind(10)

        allocate(inventario(num_equipo))

        i = 1
        print *, '                             | Equipo              | Cantidad | Precio Unitario | Ubicacion'
        print *, '-------------------------------------------------------------------------------------------'
        do
            read(10, '(A)', iostat=ios) linea
            if (ios /= 0) exit
            call parsear_lineaInventario(linea, nombre, cantidad, precio_unitario, ubicacion)
            inventario(i)%nombre = nombre
            inventario(i)%cantidad = cantidad
            inventario(i)%precio_unitario = precio_unitario
            inventario(i)%ubicacion = ubicacion
            i = i + 1
        end do

        close(10)
    end subroutine cargar_inventario

    subroutine parsear_lineaInventario(linea, nombre, cantidad, precio_unitario, ubicacion)
        implicit none
        character(len=*), intent(in) :: linea
        character(len=20), intent(out) :: nombre, ubicacion
        integer, intent(out) :: cantidad
        real, intent(out) :: precio_unitario
        integer :: pos1, pos2, pos3, ios

        pos1 = index(linea, ';')
        pos2 = index(linea(pos1+1:), ';') + pos1
        pos3 = index(linea(pos2+1:), ';') + pos2

        nombre = adjustl(linea(14:pos1-1))
        read(linea(pos1+1:pos2-1), '(I10)', iostat=ios) cantidad
        read(linea(pos2+1:pos3-1), '(F10.2)', iostat=ios) precio_unitario
        ubicacion = adjustl(linea(pos3+1:))

        print *, 'Inventario cargado con exito...', nombre, cantidad, precio_unitario, ubicacion
    end subroutine parsear_lineaInventario

    !agregar stock a un equipo
    subroutine agregar_stock(nombre_archivo, inventario, num_equipo)
        implicit none
        character(len=*), intent(in) :: nombre_archivo
        type(equipo), intent(inout) :: inventario(:)
        integer, intent(inout) :: num_equipo
        character(len=100) :: linea
        integer :: j, ios
        character(len=20) :: nombre, ubicacion
        integer :: cantidad
        logical :: encontrado

        open(unit=10, file=nombre_archivo, status='old', action='read', iostat=ios)
        if (ios /= 0) then
            print *, 'Error al abrir el archivo', trim(nombre_archivo)
            return
        end if

        do
            read(10, '(A)', iostat=ios) linea
            if (ios /= 0) exit
            if(index(linea, 'agregar_stock') == 1) then
                call parsear_instrucciones(linea, nombre, cantidad, ubicacion)
                encontrado = .false.
                do j = 1, num_equipo
                    if (inventario(j)%nombre == nombre .and. inventario(j)%ubicacion == ubicacion) then
                        inventario(j)%cantidad = inventario(j)%cantidad + cantidad
                        encontrado = .true.
                        print *, 'Se agrego ', cantidad, ' unidades al equipo ', nombre, ' en la ubicacion ', ubicacion
                        print *, '-------------------------------------------------------------------------------------------'
                        exit
                    end if
                end do
                if (.not. encontrado) then
                    print *, 'No se encontro el equipo ', nombre, ' en la ubicacion ', ubicacion
                    print *, '-------------------------------------------------------------------------------------------'
                end if
            end if
        end do

        close(10)
        
    end subroutine agregar_stock    


    !parsear linea de movimiento
    subroutine parsear_instrucciones(linea, nombre, cantidad, ubicacion)
        implicit none
        character(len=*), intent(in) :: linea
        character(len=20), intent(out) :: nombre, ubicacion
        integer, intent(out) :: cantidad
        integer :: pos1, pos2, ios

        
        if (index(linea, 'agregar_stock') > 0) then
            pos1 = index(linea, ';')
            pos2 = index(linea(pos1+1:), ';') + pos1 !posicion del segundo punto y coma, se suma pos1 para obtener la posicion en la linea original

            nombre = trim(adjustl(linea(15:pos1-1))) !se obtiene el nombre del equipo, se ajusta a la izquierda y se elimina los espacios en blanco
            read(linea(pos1+1:pos2-1), '(I10)', iostat=ios) cantidad
            ubicacion = trim(adjustl(linea(pos2+1:)))
        elseif (index(linea, 'eliminar_equipo') > 0) then
            pos1 = index(linea, ';')
            pos2 = index(linea(pos1+1:), ';') + pos1

            nombre = adjustl(linea(16:pos1-1))
            read(linea(pos1+1:pos2-1), '(I10)', iostat=ios) cantidad !se lee la cantidad de equipos a eliminar 
            ubicacion = adjustl(linea(pos2+1:))
        end if
       
    end subroutine parsear_instrucciones


    subroutine eliminar_equipos(nombre_archivo, inventario, num_equipo)
        implicit none
        character(len=*), intent(in) :: nombre_archivo
        type(equipo), intent(inout) :: inventario(:)
        integer, intent(inout) :: num_equipo
        character(len=100) :: linea
        integer :: j, ios
        character(len=20) :: nombre, ubicacion
        integer :: cantidad
        logical :: encontrado

        open(unit=10, file=nombre_archivo, status='old', action='read', iostat=ios)
        if (ios /= 0) then
            print *, 'Error al abrir el archivo', trim(nombre_archivo)
            return
        end if

        do
            read(10, '(A)', iostat=ios) linea
            if (ios /= 0) exit
            if(index(linea, 'eliminar_equipo') == 1) then
                call parsear_instrucciones(linea, nombre, cantidad, ubicacion)
                encontrado = .false.
                do j = 1, num_equipo
                if (trim(inventario(j)%nombre) == trim(nombre) .and. trim(inventario(j)%ubicacion) == trim(ubicacion)) then
                    encontrado = .true.
                    if (cantidad <= inventario(j)%cantidad) then
                    inventario(j)%cantidad = max(0, inventario(j)%cantidad - cantidad)  ! Evitar cantidades negativas
                    print *, 'Se eliminaron ', cantidad, ' unidades del equipo ',nombre,' en la ubicacion ',ubicacion
                    print *, '-------------------------------------------------------------------------------------------'
                    if (inventario(j)%cantidad == 0) then
                        !si la cantidad es 0 se elimina el equipo
                        inventario(j) = inventario(num_equipo)
                        num_equipo = num_equipo - 1
                    end if
                    else
                    print *, 'No se pueden eliminar ', cantidad, ' unidades de : ', inventario(j)%nombre, ' Solo quedan ', inventario(j)%cantidad, ' disponibles.'
                    print *, '-------------------------------------------------------------------------------------------'
                    end if
                    exit
                end if
                end do
                if (.not. encontrado) then
                print *, 'No se encontro el equipo ', nombre, ' en la ubicacion ', ubicacion
                print *, '-------------------------------------------------------------------------------------------'
                end if
            end if
        end do

        close(10)
        
    end subroutine eliminar_equipos

    subroutine mostrar_inventario(inventario, num_equipo)
        implicit none
        type(equipo), intent(in) :: inventario(:)
        integer, intent(in) :: num_equipo
        real :: valor_total
        integer :: i

        print *, 'Inventario: '
        print *, 'Equipo               | Cantidad | Precio Unitario | valor_total           |  Ubicacion'
        print *, '-----------------------------------------------------------------------------------------'
        do i = 1, num_equipo
            valor_total = inventario(i)%cantidad * inventario(i)%precio_unitario
            print '(A20, I10, 5x, A1,F14.2, 5x, A1,F14.2, A20)', trim(inventario(i)%nombre), &
                inventario(i)%cantidad, "$", inventario(i)%precio_unitario, "$", valor_total, & 
                trim(inventario(i)%ubicacion)
        end do
        close(20)
            
    end subroutine mostrar_inventario

    !Mostar el inventario en un archivo de texto .txt
    subroutine mostrar_inventario_txt(nombre_archivo, inventario, num_equipo)
        implicit none
        character(len=*), intent(in) :: nombre_archivo
        type(equipo), intent(in) :: inventario(:)
        integer, intent(in) :: num_equipo
        real :: valor_total
        integer :: i, ios

        ! Abrir el archivo en modo escritura, sobreescribiendo si existe
        open(unit=20, file=nombre_archivo, status='replace', action='write', iostat=ios)
        if (ios /= 0) then
            print *, 'Error al abrir el archivo', trim(nombre_archivo)
            return
        end if

        ! Escribir el encabezado del informe
        write(20, '(A)') 'Inventario:'
        write(20, '(A)') 'Equipo               |Cantidad | Precio Unitario    | Valor Total          |   Ubicación'
        write(20, '(A)') '------------------------------------------------------------------------------------------------'
        print *, ' '
        print *, 'se ha creado el archivo inventario.txt coorectamente'

        ! Escribir los datos de cada equipo
        do i = 1, num_equipo
            valor_total = inventario(i)%cantidad * inventario(i)%precio_unitario
            write(20, '(A20, I10, 5x, "$",F15.2, 5x, "$",F15.2, A20)') trim(adjustl(inventario(i)%nombre)), &
                                                inventario(i)%cantidad, &
                                                inventario(i)%precio_unitario, &
                                                valor_total, &
                                                trim(adjustl(inventario(i)%ubicacion))
        end do

        close(20)
    end subroutine mostrar_inventario_txt

end program practica1


