# Python script to submit N instances of the 'nlst-workflows'.
# After submitting all workflows, the script will wait until the message queue is empty.
#
# Usage: python test_workflow_driver.py <number_of_runs>

import logging
import sys
import datetime
import time
from rabbitmq_producer import publish_messages, wait_for_queues
import threading

LOG_FORMAT = '%(levelname)s: %(message)s'
LOGGER = logging.getLogger(__name__)
LOG_FILE = "test_workflow_driver.log" # in current directory
NLST_WORKFLOW = 'nlst-workflow'
SLEEP_TIME = 0 # time to wait before sending the next message

def worker(patient_ids):
    '''Function that sends the messages to execute the runs.'''

    for patient_id in patient_ids:
        LOGGER.info("Submitting message for patient #: %s" % patient_id)
    
        msg_queue = NLST_WORKFLOW
        num_msgs = 1
        msg_dict = { 'Patient': patient_id }
    
        publish_messages(msg_queue, num_msgs, msg_dict)

    return


def main(patient_ids):
    
    logging.basicConfig(level=logging.CRITICAL, format=LOG_FORMAT)
        
    startTime = datetime.datetime.now()
    logging.critical("Start Time: %s" % startTime.strftime("%Y-%m-%d %H:%M:%S") )

    # send all messages in a separate thread
    # do not wait till completion
    t = threading.Thread(target=worker, args=(patient_ids,))
    t.start()
    
    # wait for RabbitMQ server to process all messages in all queues
    wait_for_queues(delay_secs=10, sleep_secs=10)
    
    stopTime = datetime.datetime.now()
    logging.critical("Stop Time: %s" % stopTime.strftime("%Y-%m-%d %H:%M:%S") )
    logging.critical("Elapsed Time: %s secs" % (stopTime-startTime).seconds )

    # write log file (append to existing file)
    with open(LOG_FILE, 'a') as log_file:
        log_file.write('elapsed_time_sec=%s\n' % (stopTime-startTime).seconds)
                        

if __name__ == '__main__':
    """ Parse command line arguments. """
    
    #if len(sys.argv) < 1:
    #    raise Exception("Usage: python nlst_workflow_driver.py <patient number>")
    #else:
    #   patient = int( sys.argv[1] )
    
    #patient_ids = range(10)
    patient_ids = ["217676", "217724", "218035", "218098", "218307", "218420",
                   "218757", "218810", "218056", "218252"]
    main(patient_ids)
