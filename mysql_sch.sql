drop table if exists evts_log;
create table evts_log
(   id int auto_increment primary key,
    version_id int not null,
    evt_name varchar(20) not null,   
    step int not null,
    debug_msg varchar(1000) not null,
    dt_when_logged datetime not null,
    evt_status varchar(255)
);

drop table if exists version_counter;
create table version_counter(
    id int auto_increment primary key,
    used_by varchar(255) not null,
    created_at TIMESTAMP DEFAULT convert_tz(UTC_TIMESTAMP(),'+00:00', '+05:30') not null

);

DELIMITER $$
create event collect_order_summary on schedule every 5 minute starts CURRENT_TIMESTAMP
on completion preserve
do begin
    declare log_msg varchar(1000);
    declare current_version int default 0;
    declare event_alias varchar(20);

    set event_alias:='ev_1_order_summary';
    if GET_LOCK('ev_1_order_summary_lock',-1) is not TRUE then
        SIGNAL SQLSTATE '45000' set MESSAGE_TEXT = 'failed to obtain lock; not continuing; ';
    end if;
    insert version_counter(used_by) values (event_alias);
    select last_insert_id() into current_version;
    insert evts_log(version_id, evt_name, step, debug_msg, dt_when_logged, evt_status)
    select current_version as version_id, event_alias, 1, "Event Fired, Attempting data collection and write", convert_tz(UTC_TIMESTAMP(), '+00:00', '+05:30'), "collect-and-write";
    insert order_summary (user_id, task_status, order_status, order_no, order_id, address, task_id, final_amount,
    requote_amount, promotional_amount, extra_amount, reschedule_reason_id, cancel_reason_id, initial_amount,
    coupon_amount, business_type_id, txn_id, fe_remark, remark, timestamp, version)
    select
        oth.user_id,
        oth.task_status_id as task_status,
        oth.order_status_id as order_status,
        oth.order_no,
        oth.order_id,
        p.apartment as address,
        oth.order_task_id as task_id,
        oth.final_amount,
        oth.requote_amount,
        oth.promotional_amount,
        oth.extra_amount,
        oth.reschedule_reason_id,
        oth.cancel_reason_id,
        o.intial_amount as initial_amount,
        o.coupon_amount,
        o.business_type_id,
        o.txn_id,
        ot.fe_remarks as fe_remark,
        ot.remark,
        oth.created_at as timestamp,
        current_version as version
        from
        order_task_history as oth
        inner join orders as o on (oth.order_id = o.id)
        left join order_task as ot on (oth.order_task_id = ot.id)
        inner join pickup_address as p on (o.pickup_address_id = p.id)
        where
        oth.created_at >= DATE_FORMAT(convert_tz(UTC_TIMESTAMP(),'+00:00','+05:30'), '%Y-%m-%d')
        and p.is_active = 1;
    insert evts_log(version_id, evt_name, step, debug_msg, dt_when_logged, evt_status)
    select current_version as version_id, event_alias, 2, "Removing previous version", convert_tz(UTC_TIMESTAMP(), '+00:00', '+05:30'), "removing";
    delete from order_summary where version != current_version;
    -- insert evts_log(version_id, evt_name, step, debug_msg, dt_when_logged, evt_status)
    -- select current_version as version_id, event_alias, 3, "Assigning current version,", convert_tz(UTC_TIMESTAMP(), '+00:00', '+05:30'), "updating";
    -- update order_summary set version=current_version where version is NULL;
    insert evts_log(version_id, evt_name, step, debug_msg, dt_when_logged, evt_status)
    select current_version as version_id, event_alias, 3, "Event Done", convert_tz(UTC_TIMESTAMP(), '+00:00', '+05:30'), "finish";
    do RELEASE_LOCK('ev_1_order_summary_lock');
end$$
DELIMITER ;
