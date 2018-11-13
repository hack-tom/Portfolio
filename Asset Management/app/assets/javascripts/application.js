//= require jquery_ujs
//= require select2
//= require_tree .

$(document).ready(function () {
    // Dropdowns
    var $dropdowns = getAll('.dropdown:not(.is-hoverable)');

    if ($dropdowns.length > 0) {
        $dropdowns.forEach(function ($el) {
            $el.addEventListener('click', function (event) {
                event.stopPropagation();
                $el.classList.toggle('is-active');
            });
        });

        document.addEventListener('click', function (event) {
            $dropdowns.forEach(function ($el) {
                $el.classList.remove('is-active');
            });
        });
    }

    // Navigation Burger menu
    // Get all "navbar-burger" elements
    var $navbarBurgers = getAll('.navbar-burger');

    // Check if there are any navbar burgers
    if ($navbarBurgers.length > 0) {

        // Add a click event on each of them
        $navbarBurgers.forEach(function ($el) {
            $el.addEventListener('click', function () {

                // Get the target from the "data-target" attribute
                var target = $el.dataset.target;
                var $target = document.getElementById(target);

                // Toggle the class on both the "navbar-burger" and the "navbar-menu"
                $el.classList.toggle('is-active');
                $target.classList.toggle('is-active');

            });
        });
    }

    // Pickadate purchaseDate on creating assets
    $("#purchaseDate").pickadate({
        format: 'd mmmm yyyy',
        clear: ''
    });

    var startDate = $('#startDate');
    var endDate = $('#endDate');
    var startTime = $('#startTime');
    var endTime = $('#endTime');

    // Pickadate startDate on creating booking
    startDate.pickadate({
        format: 'd mmmm yyyy',
        clear: '',
        max: gon.max_start_date,
        onStart: function () {
            if (gon.initial_disable_dates != null && gon.initial_disable_dates.length !== 0) {
                this.set('disable', gon.initial_disable_dates);
            }

            // If it is after 11:00 PM, then mininum start date is tomorrow
            if (moment().hour() == 23) {
                this.set('min', moment().add(1, 'd').toDate());
            } else {
                this.set('min', moment());
            }

            // Initial earliest available start date
            if (gon.initial_start_date != null) {
                this.set('select', gon.initial_start_date, {
                    format: 'yyyy-mm-dd'
                });
            } else {
                this.set('select', this.get('highlight'));
            }
        }
    });

    // Pickadate endDate on creating booking
    endDate.pickadate({
        format: 'd mmmm yyyy',
        clear: '',
        min: moment(),
        onStart: function () {
            // if (gon.max_end_date.length !== 0) {
            //     this.set('max', gon.max_end_date)
            // }

            // if (gon.initial_disable_dates.length !== 0) {
            //     this.set('disable', gon.initial_disable_dates);
            // }

            endDate.prop('disabled', true);
        }
    });

    // Timepicker startTime on creating booking
    startTime.pickatime({
        clear: '',
        min: moment(),
        interval: 60
    });

    // Timepicker endTime on creating booking
    endTime.pickatime({
        clear: '',
        min: moment(),
        interval: 60,
        onStart: function () {
            endTime.prop('disabled', true);
        }
    });

    $('.datepicker').change(function () {
        if ($(this).attr('id') === 'startDate') {
            var start_date = new Date(startDate.val());
            var end_date = new Date(endDate.val());

            // Do not allow endDate to be smaller than start date
            if (end_date < start_date && endDate.val()) {
                endDate.pickadate('picker').clear();
            }

            endDate.pickadate('picker').set('min', start_date);

            // If the start date is today, set the minimum start time to now
            if (moment().format('D MMMM YYYY') === startDate.val()) {
                startTime.pickatime('picker').set('min', moment());
            } else {
                startTime.pickatime('picker').set('min', false);
            }

            startTime.pickatime('picker').clear();

            // Dynamic disable startTime when startDate is changed
            $.ajax({
                type: "GET",
                url: "start_date",
                data: {
                    start_date: new Date(startDate.val()),
                    end_date: new Date(endDate.val())
                },
                dataType: 'json',
                success: function (data) {
                    startTime.pickatime('picker').set('enable', true);
                    startTime.pickatime('picker').set('disable', data.disable_start_time);

                    // Pre-select earliest start time, TESTING WILL BREAK
                    startTime.pickatime('picker').set('select', 0);
                }
            });
        } else {
            // Dynamic disable endTime when endDate is changed
            if (endDate.val()) {
                $.ajax({
                    type: "GET",
                    url: "end_date",
                    data: {
                        start_date: new Date(startDate.val()),
                        end_date: new Date(endDate.val()),
                        start_time: new Date(startDate.val() + ' ' + startTime.val())
                    },
                    dataType: 'json',
                    success: function (data) {

                        if (data.max_end_time.length > 0) {
                            endTime.pickatime('picker').set('max', data.max_end_time)
                        } else {
                            endTime.pickatime('picker').set('max', false)
                        }
                    }
                });
            }
        }

        // Prevent user to input smaller endTime than startTime
        disableEndInput();
        checkTimes();
    });

    startDate.trigger('change');

    // Prevent endTime smaller than startTime on the same date
    startTime.change(function () {
        disableEndInput();
        checkTimes();

        if (endDate.val()) {
            endDate.pickadate('picker').clear();
        }

        if (startTime.val()) {
            $.ajax({
                type: "GET",
                url: "end_date",
                data: {
                    start_date: new Date(startDate.val()),
                    start_time: new Date(startDate.val() + ' ' + startTime.val())
                },
                dataType: 'json',
                success: function (data) {
                    if (data.max_end_date.length > 0) {
                        endDate.pickadate('picker').set('max', data.max_end_date);
                    } else {
                        endDate.pickadate('picker').set('max', false);
                    }
                }
            });
        }
    });

    // Clear the endTime when endDate is changed, for checking peripherals purposes
    endDate.change(function () {
        if (endTime.val()) {
            endTime.pickatime('picker').clear();
        }
    });

    // Prevent peripherals selection unless all dates and times are filled
    endTime.change(function () {
        disablePeripherals();
    });

    // Check the time when timepicker is changed
    function checkTimes() {
        var start_date = startDate.val();
        var end_date = endDate.val();

        // Check if end time is larger than start time on the same date
        if (start_date === end_date || end_date === '') {
            var start_time = new Date(start_date + ' ' + startTime.val());
            var end_time = new Date(end_date + ' ' + endTime.val());

            // If start time is 11:00 PM, then end date must be the next day
            if (startTime.val() === "11:00 PM") {
                end_date = moment(new Date(start_date)).add(1, 'd');
                endDate.pickadate('picker').set('min', moment(end_date).toDate());

                // Clear the endDate when startTime is changed
                if (endDate.val()) {
                    endDate.pickadate('picker').clear();
                }
            } else {
                endDate.pickadate('picker').set('min', start_date);
                endDate.pickadate('picker').set('highlight', start_date);
            }

            // Do not allow end time to be smaller than start time on the same date
            if (end_time <= start_time && end_time) {
                endTime.pickatime('picker').clear();
            }

            // Clear the endTime when startTime is changed
            if (endTime.val()) {
                endTime.pickatime('picker').clear();
            }

            // If end date is empty, then end time has no minimum
            if (endDate.val()) {
                endTime.pickatime('picker').set('min', moment(start_time).add(1, 'h').toDate());
            } else {
                endTime.pickatime('picker').set('min', false);
            }
        } else {
            // Start date is larger than end date
            endTime.pickatime('picker').set('min', false);

            // If start time is 11:00 PM, disable the option for end date to be start date
            if (startTime.val() !== "11:00 PM") {
                endDate.pickadate('picker').set('min', moment(new Date(start_date)).toDate());

                if (endDate.val() === '') {
                    endDate.pickadate('picker').set('highlight', moment(new Date(start_date)).toDate());
                }
            }
        }
    }

    // Disable end date and end time input
    function disableEndInput() {
        // Disable the end date and end time if start date and start time are not filled
        if (startDate.pickadate('picker') != undefined &&
            (startDate.pickadate('picker').get() == '' ||
                startTime.pickatime('picker').get() == '')) {
            endDate.prop('disabled', true);
            endTime.prop('disabled', true);
        } else {
            endDate.prop('disabled', false);
            endTime.prop('disabled', false);
        }
    }

    // Disable peripherals
    disablePeripherals();

    function disablePeripherals() {
        // Disable the peripherals unless all dates and times are filled
        var peripherals = $('#peripherals');

        if (startDate.pickadate('picker') != undefined &&
            (startDate.pickadate('picker').get() == '' ||
                startTime.pickatime('picker').get() == '' ||
                endDate.pickadate('picker').get() == '' ||
                endTime.pickatime('picker').get() == '')) {

            peripherals.prop('disabled', true);
        } else {
            peripherals.prop('disabled', false);
        }

        if (peripherals.val()) {
            peripherals.val(null).trigger('change');
        }
    }

    // Bulma notification
    $(document).on('click', '.notification > button.delete', function () {
        this.parentNode.remove();
    });

    // Datatable
    $("#users, #categories, #bookings, #bookings_other").each(function () {
        if ($(this).attr('id') === 'bookings' || $(this).attr('id') === 'bookings_other') {
            $(this).DataTable({
                columnDefs: [{
                    orderable: false,
                    targets: '_all'
                }],
                "drawCallback": function (settings) {
                    if (!$(this).parent().hasClass("table-is-responsive")) {
                        $(this).wrap('<div class="table-is-responsive"></div>');
                    }
                }
            });
        } else {
            $(this).DataTable({
                "drawCallback": function (settings) {
                    if (!$(this).parent().hasClass("table-is-responsive")) {
                        $(this).wrap('<div class="table-is-responsive"></div>');
                    }
                }
            });
        }

    });

    $("#bookings_wrapper").removeClass("container");

    // Datatable details dropdown
    var details = getAll('.details');
    var detailsButtons = getAll('.details-control');

    if (detailsButtons.length > 0) {
        $('#bookings tbody, #bookings_other tbody').on('click', '.details-control', function () {
            var target = $(this).data('target');
            var $target = document.getElementById(target);
            if ($target.classList.contains('is-hidden')) {
                $target.previousSibling.classList.add('shown');
                $target.classList.remove('is-hidden');
            } else {
                $target.previousSibling.classList.remove('shown');
                $target.classList.add('is-hidden');
            }
        });
    }

    // For searching browse by categories
    var table = $("#assets").DataTable({
        "drawCallback": function (settings) {
            if (!$(this).parent().hasClass("table-is-responsive")) {
                $(this).wrap('<div class="table-is-responsive"></div>');
            }
        }
    });

    // Use gon to get ruby variables into JS, for categories filtering
    if (gon.category != null) {
        table.search(gon.category).draw();
    }

    // Select2
    $.fn.select2.defaults.set("width", "100%");
    $('.select2').select2();

    // Preselect parent assets
    if (gon.parent_id !== undefined) {
        $('#item_add_parents').val(gon.parent_id).trigger('change');
    }

    // Peripherals ajax
    endTime.change(function () {
        $('#peripherals').empty();
    });

    $('#peripherals').change(function () {
        if (endTime.val()) {
            $.ajax({
                type: "GET",
                url: "peripherals",
                data: {
                    start_datetime: startDate.val() + ' ' + startTime.val(),
                    end_datetime: endDate.val() + ' ' + endTime.val(),
                },
                dataType: 'json',
                success: function (data, page) {
                    $('#peripherals').select2({
                        data: $.map(data, function (item, i) {
                            return {
                                id: item.id,
                                text: item.serial
                            }
                        })
                    })
                }
            });
        }
    });

    // Phone number validation
    var number = document.getElementById("number");
    if (number != null) {
        inputTypeNumberPolyfill.polyfillElement(number);
    }

    // Image upload show file name
    $('.file-input').change(function () {
        var i = $(this).prev('label').clone();
        var file = $('.file-input')[0].files[0].name;
        $("#file_name").text(file);
    });

    // Zoom.js config
    $('#zoom').zoom({
        magnify: 1.15
    });

    // Launch and close the modal
    function getAll(selector) {
        return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
    }

    var modals = getAll('.modal');
    var modalButtons = getAll('.modal-button');
    var modalCloses = getAll('.modal-close');

    // Open the modal
    if (modalButtons.length > 0) {
        $('#assets tbody').on('click', '.modal-button', function () {
            var target = $(this).data('target');
            var $target = document.getElementById(target);
            $target.classList.add('is-active');
        });
    }

    // Close modal button
    if (modalCloses.length > 0) {
        $(document).on('click', '.modal-close', function () {
            closeModals();
        });
    }

    // Close modal when Esc is pressed
    $(document).keydown(function () {
        var e = event || window.event;
        if (e.keyCode === 27) {
            closeModals();
        }
    });

    // Close modal when click outside of image
    $(document).click(function (e) {
        if (!$(e.target).closest(".image-modal-image").length &&
            !$(e.target).closest(".modal-button").length) {
            closeModals();
        }
    });

    // closeModals function
    function closeModals() {
        $('.modal').removeClass('is-active');
    }

    // Notifications
    (function () {
        var Notifications,
            bind = function (fn, me) {
                return function () {
                    return fn.apply(me, arguments);
                };
            };

        Notifications = (function () {
            function Notifications() {
                this.handleSuccess = bind(this.handleSuccess, this);
                this.handleHover = bind(this.handleHover, this);
                this.notifications = $("[data-behavior='notifications']");
                if (this.notifications.length > 0) {
                    this.setup();
                }
            }

            Notifications.prototype.setup = function () {
                $("[data-behavior='notification-link']").mouseenter(this.handleHover);
                return $.ajax({
                    url: "/notifications.json",
                    dataType: "JSON",
                    method: "GET",
                    success: this.handleSuccess
                });
            };

            Notifications.prototype.handleHover = function () {
                if ($("[data-behavior='unread-count']").attr('data-badge') !== void 0) {
                    return $.ajax({
                        url: "/notifications/mark_as_read",
                        dataType: "JSON",
                        method: "PUT",
                        success: function () {
                            return $("[data-behavior='unread-count']").removeAttr('data-badge');
                        }
                    });
                }
            };

            Notifications.prototype.handleSuccess = function (data) {
                var items, items_mobile, unread_count;
                items = $.map(data, function (notification) {
                    if (notification.context === "AM") {
                        if ((notification.action === "returned") || (notification.action === "requested")) {
                            return "<a class='navbar-item'>" + notification.notifiable.booker + " has " + notification.action + ": " + notification.notifiable.itemname + "</a> <hr class='navbar-divider>";
                        } else if (notification.action === "overdue") {
                            return "<a class='navbar-item'>" + notification.notifiable.booker + " has not returned " + notification.notifiable.itemname + " on time</a> <hr class='navbar-divider>";
                        } else if ((notification.action === "started") || (notification.action === "cancelled")) {
                            return "<a class='navbar-item'>" + notification.notifiable.booker + "'s booking for " + notification.notifiable.itemname + " has been " + notification.action + "</a> <hr class='navbar-divider>";
                        } else if (notification.action === "reported") {
                            return "<a class='navbar-item'>An issue has been reported with " + notification.notifiable.itemname + "</a> <hr class='navbar-divider>";
                        }
                    } else if (notification.context === "U") {
                        if ((notification.action === "approved") || (notification.action === "rejected")) {
                            return "<a class='navbar-item'>Your " + notification.notifiable.type + " for " + notification.notifiable.itemname + " has been " + notification.action + "</a> <hr class='navbar-divider>";
                        } else if (notification.action === "started") {
                            return "<a class='navbar-item'>Your " + notification.notifiable.type + " for " + notification.notifiable.itemname + " has " + notification.action + "</a> <hr class='navbar-divider>";
                        } else if (notification.action === "overdue") {
                            return "<a class='navbar-item'>Your " + notification.notifiable.type + " for " + notification.notifiable.itemname + " is " + notification.action + "</a> <hr class='navbar-divider>";
                        } else if (notification.action === "itemdeleted") {
                            return "<a class='navbar-item'>" + notification.notifiable.itemname + "is no longer available, your" + notification.notifiable.type + " has been cancelled. </a> <hr class='navbar-divider>";
                        }
                    }
                });

                unread_count = $.map(data, function (notification) {
                    if (!notification.read) {
                        return "1";
                    }
                });

                if (items.length === 0) {
                    $("[data-behavior='notification-items']").html("<a class='navbar-item'>No new notifications</a>");
                    $("[data-behavior='notification-items-mobile']").html("<a class='dropdown-item'>No new notifications</a>");
                    return $("[data-behavior='unread-count']").removeAttr('data-badge');
                } else {
                    $("[data-behavior='notification-items'], [data-behavior='notification-items-mobile']").html(items);
                    if (unread_count.length === 0) {
                        return $("[data-behavior='unread-count']").removeAttr('data-badge');
                    } else {
                        return $("[data-behavior='unread-count']").attr('data-badge', unread_count.length);
                    }
                }
            };

            return Notifications;

        })();

        jQuery(function () {
            return new Notifications;
        });

    }).call(this);

});